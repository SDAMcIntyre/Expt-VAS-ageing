#!/usr/bin/env python2
# -*- coding: utf-8 -*-

from psychopy import visual, core, gui, data, event
import numpy, random, os, pygame
from math import *

# -- DISPLAY TEXT --

displayTextDictionary = {
            'en': {'waitMessage':'Please wait.',
                    'interStimMessage':'...',
                    'finishedMessage':'Session finished.',
                    'pleasantQuestion':'How pleasant was the last stimulation on your skin?',
                    'pleasantMin':'unpleasant',
                    'pleasantMax':'very pleasant',
                    'intensityQuestion':'How intense was the last stimulation on your skin?',
                    'intensityMin':'not at all',
                    'intensityMax':'very intense',
                    'acceptPreText':'click line',
                    'acceptText':'accept'},
                    
            'sv': {'waitMessage':u'Vänligen vänta.',
                    'interStimMessage':'...',
                    'finishedMessage':'Session avslutad.',
                    'pleasantQuestion':'Hur behaglig var den senaste stimuleringen?',
                    'pleasantMin':'obehaglig',
                    'pleasantMax':u'väldigt behaglig',
                    'intensityQuestion':'Hur intensiv var den senaste stimuleringen?',
                    'intensityMin':'inte alls',
                    'intensityMax':u'väldigt intensiv',
                    'acceptPreText':u'klicka på linjen',
                    'acceptText':'acceptera'}
            }

# --


# -- GET INPUT FROM THE EXPERIMENTER --

exptInfo = {'00. Experiment':'AT',
            '01. Participant Code':'00', 
            '02. Notes (e.g. site, tegaderm)':'practice', 
            '03. Number of trials':25, 
            '04. Question':('pleasantness','intensity'),
            '05. Participant language':('en','sv'),
            '06. Folder for saving data':'data',
            '07. Display screen number':0}

dlg = gui.DlgFromDict(exptInfo, title='Experiment details')
if dlg.OK:
    pass ## continue
else:
    core.quit() ## the user hit cancel so exit

exptInfo['08. Date and time']= data.getDateStr(format='%Y-%m-%d_%H-%M-%S') ##add the current time

## select dictionary according to participant language
displayText = displayTextDictionary[exptInfo['05. Participant language']]

# --


# -- MAKE FOLDER/FILES TO SAVE DATA --

dataFolder = './'+exptInfo['06. Folder for saving data']+'/'
if not os.path.exists(dataFolder):
    os.makedirs(dataFolder)

fileName = dataFolder + exptInfo['08. Date and time'] + '_' + exptInfo['01. Participant Code']
infoFile = open(fileName+'_info.csv', 'w') 
for k,v in exptInfo.items(): infoFile.write(k + ',' + str(v) + '\n')
infoFile.close();
dataFile = open(fileName+'_'+exptInfo['04. Question']+'_data.csv', 'w')
dataFile.write('trialnum,question,rating\n')

# ----

# -- SETUP CONFIRMATION SOUND --

pygame.mixer.pre_init() 
pygame.mixer.init()
pingSound = pygame.mixer.Sound('ping.wav')

# ----


# -- SETUP VISUAL ANALOG SCALES AND VISUAL PROMPTS --

## display window and mouse input
win = visual.Window(fullscr=True, screen=1, units='norm', monitor='testMonitor')
mouse = event.Mouse()

## instructions text
waitMessage = visual.TextStim(win, text=displayText['waitMessage'], units='norm')
interStimMessage = visual.TextStim(win, text=displayText['interStimMessage'], units='norm')
finishedMessage = visual.TextStim(win, text=displayText['finishedMessage'], units='norm')

barMarker = visual.TextStim(win, text='|', units='norm')
## pleasant VAS
pleasantVAS = visual.RatingScale(win, low=-10, high=10, precision=10, 
    showValue=False, marker=barMarker, scale = displayText['pleasantQuestion'],
    tickHeight=1, stretch=1.5, size=0.8, 
    labels=[displayText['pleasantMin'], displayText['pleasantMax']],
    tickMarks=[-10,10], mouseOnly = True, pos=(0,0),
    acceptPreText = displayText['acceptPreText'],
    acceptText = displayText['acceptText'])

## intensity VAS
intensityVAS = visual.RatingScale(win, low=-10, high=10, precision=10, 
    showValue=False, marker=barMarker, scale = displayText['intensityQuestion'],
    tickHeight=1, stretch=1.5, size=0.8,
    labels=[displayText['intensityMin'], displayText['intensityMax']],
    tickMarks=[-10,10], mouseOnly = True, pos=(0,0),
    acceptPreText = displayText['acceptPreText'],
    acceptText = displayText['acceptText'])


# --


# -- RUN THE EXPERIMENT --

## tell participant to wait (experimenter triggers experiment with keyboard)
event.clearEvents()
waitMessage.draw()
win.flip()
if 'escape' in event.waitKeys():
    dataFile.close()
    core.quit()


# main loop
else:
    
    ## loop through the trials
    for trialNum in range(exptInfo['03. Number of trials']):
        pleasantVAS.reset()
        intensityVAS.reset()
        
        ## display stim message and cue experimenter
        event.clearEvents()
        interStimMessage.draw()
        win.flip()
        
        ## present VAS
        core.wait(3.0)
        event.clearEvents()
        while pleasantVAS.noResponse and intensityVAS.noResponse:
            if exptInfo['04. Question'] == 'pleasantness':
                pleasantVAS.draw()
            elif exptInfo['04. Question'] == 'intensity':
                intensityVAS.draw()
            win.flip()
            if event.getKeys(['escape']):
                print ('user aborted')
                dataFile.close()
                core.quit()
        
        soundCh = pingSound.play()
        while soundCh.get_busy():
            pass
        
        ## check rating
        if exptInfo['04. Question'] == 'pleasantness':
            rating = pleasantVAS.getRating()
        elif exptInfo['04. Question'] == 'intensity':
            rating = intensityVAS.getRating()
        print ('trial {} of {}: {} rating (-10,10) = {}\n' .format(trialNum+1,exptInfo['03. Number of trials'],exptInfo['04. Question'],rating))
        
        ## record the data 
        dataFile.write('{},{},{}\n' .format(trialNum+1,exptInfo['04. Question'],rating))
        

# ----

# -- END OF EXPERIMENT --

print('\n=== EXPERIMENT FINISHED ===\n')

## save data to file
dataFile.close()
print('Data saved {}\n\n' .format(fileName))

## prompt at the end of the experiment
event.clearEvents()
mouse.clickReset()
finishedMessage.draw()
win.flip()
while 1:
    core.wait(2)
    core.quit()
## ----
