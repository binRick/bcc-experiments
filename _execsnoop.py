#!/usr/libexec/platform-python
# @lint-avoid-python-3-compatibility-imports
from __future__ import print_function
from bcc import BPF
import sys, json, traceback
from bcc.utils import ArgString, printb
import bcc.utils as utils
import argparse
import re
import time
import bcc_utils as bcc_utils
from collections import defaultdict

# arguments
examples = """examples:
    ./execsnoop           # trace all exec() syscalls
    ./execsnoop -x        # include failed exec()s
    ./execsnoop -t        # include timestamps
    ./execsnoop -q        # add "quotemarks" around arguments
    ./execsnoop -n main   # only print command lines containing "main"
    ./execsnoop -l tpkg   # only print command where arguments contains "tpkg"
"""
parser = argparse.ArgumentParser(
    description="Trace exec() syscalls",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=examples)
parser.add_argument("-t", "--timestamp", action="store_true",
    help="include timestamp on output")
parser.add_argument("-x", "--fails", action="store_true",
    help="include failed exec()s")
parser.add_argument("-q", "--quote", action="store_true",
    help="Add quotemarks (\") around arguments."
    )
parser.add_argument("-n", "--name",
    type=ArgString,
    help="only print commands matching this name (regex), any arg")
parser.add_argument("-l", "--line",
    type=ArgString,
    help="only print commands where arg contains this line (regex)")
parser.add_argument("--max-args", default="20",
    help="maximum number of arguments parsed and displayed, defaults to 20")
parser.add_argument("--ebpf", action="store_true",
    help=argparse.SUPPRESS)
args = parser.parse_args()

# define BPF program
bpf_text = """
#include <uapi/linux/ptrace.h>
#include <linux/sched.h>
#include <linux/fs.h>

#define ARGSIZE  256

enum event_type {
    EVENT_ARG,
    EVENT_RET,
};

struct data_t {
    u32 pid;  // PID as in the userspace term (i.e. task->tgid in kernel)
    u32 ppid; // Parent PID as in the userspace term (i.e task->real_parent->tgid in kernel)
    u32 uid;
    char comm[TASK_COMM_LEN];
    enum event_type type;
    char argv[ARGSIZE];
    int retval;
};

BPF_PERF_OUTPUT(events);

static int __submit_arg(struct pt_regs *ctx, void *ptr, struct data_t *data)
{
    bpf_probe_read(data->argv, sizeof(data->argv), ptr);
    events.perf_submit(ctx, data, sizeof(struct data_t));
    return 1;
}

static int submit_arg(struct pt_regs *ctx, void *ptr, struct data_t *data)
{
    const char *argp = NULL;
    bpf_probe_read(&argp, sizeof(argp), ptr);
    if (argp) {
        return __submit_arg(ctx, (void *)(argp), data);
    }
    return 0;
}



int syscall__execve(struct pt_regs *ctx,
    const char __user *filename,
    const char __user *const __user *__argv,
    const char __user *const __user *__envp)
{
    // create data here and pass to submit_arg to save stack space (#555)
    struct data_t data = {};
    struct task_struct *task;

    data.pid = bpf_get_current_pid_tgid() >> 32;

    task = (struct task_struct *)bpf_get_current_task();
    // Some kernels, like Ubuntu 4.13.0-generic, return 0
    // as the real_parent->tgid.
    // We use the get_ppid function as a fallback in those cases. (#1883)
    data.ppid = task->real_parent->tgid;
    	
    data.uid = bpf_get_current_uid_gid();

    bpf_get_current_comm(&data.comm, sizeof(data.comm));
    data.type = EVENT_ARG;

    __submit_arg(ctx, (void *)filename, &data);

    // skip first arg, as we submitted filename
    #pragma unroll
    for (int i = 1; i < MAXARG; i++) {
        if (submit_arg(ctx, (void *)&__argv[i], &data) == 0)
             goto out;
    }

    // handle truncated argument list
    char ellipsis[] = "...";
    __submit_arg(ctx, (void *)ellipsis, &data);
out:
    return 0;
}

int do_ret_sys_execve(struct pt_regs *ctx)
{
    struct data_t data = {};
    struct task_struct *task;

    data.pid = bpf_get_current_pid_tgid() >> 32;

    task = (struct task_struct *)bpf_get_current_task();
    // Some kernels, like Ubuntu 4.13.0-generic, return 0
    // as the real_parent->tgid.
    // We use the get_ppid function as a fallback in those cases. (#1883)
    data.ppid = task->real_parent->tgid;
    data.uid = bpf_get_current_uid_gid();

    bpf_get_current_comm(&data.comm, sizeof(data.comm));
    data.type = EVENT_RET;
    data.retval = PT_REGS_RC(ctx);
    events.perf_submit(ctx, &data, sizeof(data));

    return 0;
}
"""

bpf_text = bpf_text.replace("MAXARG", '40')
if args.ebpf:
    print(bpf_text)
    exit()

# initialize BPF
b = BPF(text=bpf_text)
execve_fnname = b.get_syscall_fnname("execve")
b.attach_kprobe(event=execve_fnname, fn_name="syscall__execve")
b.attach_kretprobe(event=execve_fnname, fn_name="do_ret_sys_execve")

# header
if args.timestamp:
    pass
    print("%-8s" % ("TIME(s)"), end="")

#print("%-16s %-6s %-6s %3s %s" % ("PCOMM", "PID", "PPID", "RET", "ARGS"))

class EventType(object):
    EVENT_ARG = 0
    EVENT_RET = 1

start_ts = time.time()
argv = defaultdict(list)

# This is best-effort PPID matching. Short-lived processes may exit
# before we get a chance to read the PPID.
# This is a fallback for when fetching the PPID from task->real_parent->tgip
# returns 0, which happens in some kernel versions.
def get_ppid(pid):
    try:
        with open("/proc/%d/status" % pid) as status:
            for line in status:
                if line.startswith("PPid:"):
                    return int(line.split()[1])
    except IOError:
        pass
    return 0

# process event
def print_event(cpu, data, size):
    event = b["events"].event(data)
    skip = False

    if event.type == EventType.EVENT_ARG:
        argv[event.pid].append(event.argv)
    elif event.type == EventType.EVENT_RET:
        if event.retval != 0 and not args.fails:
            skip = True
        if args.name and not re.search(bytes(args.name), event.comm):
            skip = True
        if args.line and not re.search(bytes(args.line),
                                       b' '.join(argv[event.pid])):
            skip = True
        if args.quote:
            argv[event.pid] = [
                b"\"" + arg.replace(b"\"", b"\\\"") + b"\""
                for arg in argv[event.pid]
            ]

        if not skip:
            if args.timestamp:
                printb(b"%-8.3f" % (time.time() - start_ts), nl="")
            ppid = event.ppid if event.ppid > 0 else get_ppid(event.pid)
            ppid = b"%d" % ppid if ppid > 0 else b"?"
            uid = event.uid if event.uid > -1 else None
            argv_text = b' '.join(argv[event.pid]).replace(b'\n', b'\\n')
            dur = int(time.time()-start_ts)
            """
            try:
              P = psutil.Process(event.pid)
              ANCESTRY, PROCS = bcc_utils.crawl_process_tree(P)
              #print(ANCESTRY)
              #sys.exit()
            except:
              #traceback.print_exc()
              ANCESTRY = None
            """
            ANCESTRY = None
            J = {'pid':event.pid,'exec':event.comm,'ppid':event.ppid,'dur':int(dur),'cmd':argv_text,'exit_code':event.retval,'uid':uid,'ancestry':ANCESTRY}
            del J['ancestry']
            MSG = json.dumps(J)
            print(MSG)
            #printb(b"%-16s %-6d %-6s %3d %s" % (event.comm, event.pid,
            #       ppid, event.retval, argv_text))
        try:
            del(argv[event.pid])
        except Exception:
            pass


# loop with callback to print_event
b["events"].open_perf_buffer(print_event)
while 1:
    try:
        b.perf_buffer_poll()
    except KeyboardInterrupt:
        exit()
