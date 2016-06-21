#!/usr/bin/env python

# Script traverses input rosetta log files and returns avg times
import sys
import math


def getTimes(fileName):
    indTimeList = []
    with open (fileName, 'r') as f:
        totTime = None
        for line in f:
            if line.startswith("protocols.jd2.JobDistributor:"):
                if line.split(' ')[1].isdigit():
                    totTime = line.split(' ')[8]
                else:
                    if line.split(' ')[5].isdigit():
                        indTimeList.append(line.split(' ')[5])
    return indTimeList, totTime
                                    
def getStats(times):
    timesFiltered = [i for i in times if i is not None]
    timesN = map(float,timesFiltered)
    N = len(timesN)
    avgTime = math.fsum(timesN)/ N
    timesMinusMean = [x - avgTime for x in timesN]
    timesMMSquared = [math.pow(x,2) for x in timesMinusMean]
    var = math.fsum(timesMMSquared) / N
    return avgTime, var

if __name__ == "__main__": 
    allIndTimes = []
    allTotTimes = []
    for fileName in sys.argv[1:]:       
       indTimeList, totTime = getTimes(fileName)
       allIndTimes.extend(indTimeList)
       allTotTimes.append(totTime)
    avgIndTime, varIndTime = getStats(allIndTimes)
    avgMin = avgIndTime/60
    varMin = varIndTime/math.pow(60,2)
    print "Expected time per structure is {0} mins with variance {1} mins".format(avgMin,varMin)
    avgTotTime, varTotTime = getStats(allTotTimes)
    avgHr = avgTotTime/3600
    varHr = varTotTime/math.pow(3600,2)
    print "Expected time per nstruct is {0} hrs with variance {1} hrs".format(avgHr,varHr)


    
