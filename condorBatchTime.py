#!/usr/bin/env python

# Script traverses input condor log files and returns avg job and node times ingnoring evictions

import sys
import argparse
import datetime as dt
import math

def mkDict(procs):
    width = len(str(procs))-1
    for i in range(0, procs):
        procStr = str(i)
        procID = procStr.zfill(width)                 
        execDict[procID] = None
        termDict[procID] = None

def timedelta_total_seconds(timedelta):
    return (
        timedelta.microseconds + 0.0 +
        (timedelta.seconds + timedelta.days * 24 * 3600) * 10 ** 6) / 10 ** 6

def getDeltaT(execProcID,termProcID):
    execStr = execDict[execProcID]
    termStr = termDict[termProcID]
    execT = dt.datetime.strptime(execStr, '%m/%d %H:%M:%S')
    termT = dt.datetime.strptime(termStr, '%m/%d %H:%M:%S')
    timeDelta = termT-execT
    try:
        totHours = timeDelta.total_seconds() / float(3600)
    except AttributeError:
        totHours = timedelta_total_seconds(timeDelta) / float(3600)
    return totHours
    

def getTimes(fileName):
    with open (fileName, 'r') as f:

        first = True
        for line in f:
            if line.startswith("001"):
                execLine = line.split(' ')[1:4]
                execProcID = execLine[0].split('.')[1]
                if execDict[execProcID] is None:
                    execTimeInfo = ' '.join(execLine[1:3])
                    execDict[execProcID] = execTimeInfo
                if first:
                    first = False
                    execDict['firstExecProcID'] = execTimeInfo
            elif line.startswith("005"):
                termLine = line.split(' ')[1:4]
                termProcID = termLine[0].split('.')[1]
                termTimeInfo = ' '.join(termLine[1:3])
                termDict[termProcID] = termTimeInfo
                deltaT = getDeltaT(termProcID, termProcID)
                allJobTimes.append(deltaT)
            else:
                continue
        try:
            
            termDict['lastTermProcID'] = termTimeInfo
            nodeDeltaT = getDeltaT('firstExecProcID', 'lastTermProcID')
            allNodeTimes.append(nodeDeltaT)
        except NameError:
            print '{} does not have any completed nodes'.format(fileName)
        
                                           
def genStats(times):
    N = len(times)
    avgTime = math.fsum(times)/ N
    timesMinusMean = [x - avgTime for x in times]
    timesMMSquared = [math.pow(x,2) for x in timesMinusMean]
    var = math.fsum(timesMMSquared) / N
    return avgTime, var
    

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="calculate batch time for each node and job from condor log file")
    parser.add_argument("-p", "--processes", type=int, \
                        help="number of processes per cluster (default: 1000)", \
                        default=1000)
    parser.add_argument("-f", "--files", nargs='*', help="condor log files (space separated)")
    args = parser.parse_args()
    if not (args.files):
        parser.error('input condor log files must be specified')

    execDict = {}
    termDict = {}
    mkDict(args.processes)

    allJobTimes = []
    allNodeTimes = []
    for fileName in args.files:
        getTimes(fileName)

    avgJobTime, varJobTime = genStats(allJobTimes)
    print 'Expected compute time per job is {0} hours with variance {1} hours'.format(avgJobTime, varJobTime) 
    avgNodeTime, varNodeTime = genStats(allNodeTimes)

    print 'Expected compute time per node is {0} hours with variance {1} hours'.format(avgNodeTime, varNodeTime) 

    
