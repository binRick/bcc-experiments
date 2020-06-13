import psutil, sys, json, traceback

def crawl_process_tree(proc):
  procs = [proc]
  acestors = []
  try:
    while True:
        ppid = procs[len(procs)-1].ppid()
        if ppid == 0:
            break
        P = psutil.Process(ppid)
        PARENT = {'pid':P.pid,'exe':P.exe,}
        ancestors.append(PARENT)
        procs.append(P)
        
  except:
    ancestors.append(traceback.format_exc())
    pass
  return json.dumps(ancestors), procs

def smart_open(filename=None, mode='r'):
    """ File OR stdout open """
    if filename and filename != '-':
        return(open(filename, mode))
    else:
        return(sys.stdout)
