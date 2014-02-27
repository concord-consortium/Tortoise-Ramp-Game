; RampGame v6
; Feb 1, 2014
; Started July 22, 2013
; Bob Tinker
; Copyright, the Concord Consortium

; This version is set up to log data
; It is a stripped down version of v5, with vast amounts of unneeded code and logic removed. 

globals [
  messages-shown                 ; counts the number of messages shown at each level
  output-width                   ; the width of the output box--used in pretty-print
  mx bx my by                    ; transformation coefs for the equations: x=mx*u + bx y=my*v + by
                                 ; x,y are used for problem coordinates, u,v for screen
  ul ur vb vt                    ; the ramp window boundaries

  starting?                      ; true when waiting for the user to press the start button
  running?                       ; true when the car is running
  ready-for-export? 
  old-car-loc
  old-running?
  ramp 
  ramp-color
  car-color
  car-shape
  car-mass
  car-offset
  car-size
  car-x                           ; the horizontal location of the car in problem units
  car-y                           ; the vertical location of the car in problem units. 
  car-speed
  car-locked?
  freeze?   ; used to freeze the game to push kids to use the lab notebook. 
;  move-ramp-left?   ; set true when the car runs off one side or the other
;  move-ramp-right?
;  y-axis
;  old-y-axis
  g        ; acceleration of gravity 9.81 m/s^2
  time     ; the model time
  dt       ; the time step
  height dist
  saved-time-series ; a list of lists containing [t, x, y, speed] for every .5 sec
  start-height  ;
  saved-starting-x
  data-saved?
  
  x-center y-center  ; the location of the center of the window screen (u=0, v=0) in x,y coordinates
  magnification      ; the ratio of pixels to meters

  ; game variables
  total-score           ; score since the beginning
  score-last-run        ; score earned in the last run
  level                 ; the current level (the user knows the levels as 'challenges')
  step                  ; the current step in the current level
  loops-at-zero         ; the number of times go is called when speed is zero before the program stops
  countdown             ; used to record the times waited, starting at loops-at-zero  
  instructions            ; text 
  number-of-hints
  friction-locked?
  starting-position-locked?
  old-friction
  old-starting-position
  starting-position-min ; the smallest starting position allowed (a negative value)
  starting-position-max
  max-score             ; the maximum score a user could earn for the current level
  n-steps               ; the number of steps in the current level
  target                ; the target location for the current step and level
  target-radius-max     ; the maximum radius at this step, corresponding to step 1
  target-radius-min     ; the minimum radius at this step, correspondind to step n-steps
  target-radius         ; the radius for this level and step
  target-max            ; the maximum position of the target 
  target-min            ; the minimum position of the target
  max-level             ; the number of levels in the game
  marker-1              ; the who of the left-hand marker of the target range
  marker-2              ; the who of the right-hand marker
  marker-3              ; the who of the target center indicator
  waiting-for-setup?    ; used to allow the user to press setup. 
  waiting-for-start?    ; used to allow the user to press start.
  final-position        ; the final position of the car at the end of a run
  next-step             ; used to carry the step info from the time it is set in analyze data to its display in setup-next-run
  next-level            ; ditto for level
  number-of-random-tries; used to detect whether a student is making random tries
  first-reward?         ; used so that the congratulations for finishing occurs only once. 
]

breed [drawing-dots drawing-dot]      ; used for the track
breed [readers reader]                ; used for read-out at the cursor
breed [markers marker]                ; used to show the target
breed [cars car]
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; Override Data Export Functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to data-export-log-event [ a b c d ]
end

to data-export-clear-last-run
end

to data-export-update-run-series [ a ]
end

to data-export-initialize [ a ]
end

to my-user-message [ msg ]
end

to my-clear-output []
end

to-report my-user-yes-or-no? [ question ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; End of preliminaries ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to startup  ; structured this way in order to have a start page
  ca        ; I use the start page for a reminder to turn on the "go" button
  reset-ticks
  draw-first-page
  set starting? true
  set waiting-for-start? false
  set running? false
  set ready-for-export? false
  set waiting-for-setup? false
end

to go                       ; this is the main forever button
  if starting? [            ; starting? is true only on startup
    ask drawing-dots [die]  ; gets rid of the startup message
    set starting? false
    initialize]             ; initialize all the variables, setup the initial view
  every dt [
    if running? [run-car]  ; computes the motion of the cars every dt seconds, if the simulation is running
  ]

  every .1 [
    act-on-changes          ; detect changes in the friction slider
    support-mouse           ; allows the mouse to move the car
    tick
  ]

end


to act-on-changes
  if freeze? [wait 5 set freeze? false]      ; freezes the game for 5 sec. 
  if friction != old-friction [              ; if the user tries to change the friction...
    ifelse friction-locked? or running?      ;   and the friction slider is supposed to be locked or the model is running
      [ wait .6 set friction old-friction 
        my-user-message "The friction is locked for this challenge."
        set friction old-friction  ]         ;   then reset the slider to its old position
      [set old-friction friction]]           ; otherwise allow the change
end

to draw-first-page
  ask patches [set pcolor grey + 2]
  create-drawing-dots 1 [
    set size .1
    setxy .4 * min-pxcor .9 * max-pycor
    set label   "Press the On/Off button to continue." ]
  create-drawing-dots 1 [
    set size .1
    setxy .5 * min-pxcor .85 * max-pycor
    set label "   Leave it on all the time." ]
  ask drawing-dots [set label-color red]
end

to initialize
  set ready-for-export? false
  set waiting-for-start? true
  set running? false
  set old-running? false
  set freeze? false
  set magnification 50    ; 
  
  set g 9.81 ; acceleration of gravity
  set dt .001 ; the time step
  set x-center 1.34 set y-center .3  ; 
  define-window      ; defines the ramp window bounded by (ul, ur, vb, bt)
  define-transforms  ; creates transforms for the ramp  (mx, my, bx, by)
  set first-reward? true
  set ramp-color blue + 2
  set ramp [[-1.3 1][0 0][.5 0][1 0][1.5 0][2 0][2.5 0][3 0][3.5 0][4 0][5 0]] ; the ramp, defined by x,y coordinates
  draw-ramp                      ; draws ramp
  ; define car variables
  set car-offset 12  ; distance the turtle center is above the ramp for magnification of 100
  set saved-starting-x -.9
  ;  make the car
  set car-size 22
  create-cars 1 [
    ht  
    ifelse level = 4 [set car-mass 200] [set car-mass 100]
    set color red
    set shape "car"
    set size car-size
    place-car saved-starting-x]

  ; markers mark the target. They are two tiny turtles linked by a thick line
  create-markers 1 [ht set marker-1 who set color red set size .1 set heading 0]
  create-markers 1 [ht set marker-2 who set color red set size .1 set heading 0
    create-link-with marker marker-1 [
      set thickness 3 set color red]]
  create-markers 1 [ht set marker-3 who set color red set size 18 set heading 0 set shape "line"]    ; create a vertical line at the center of the target
  set data-saved? true
  set output-width  46     ; characters in the output box, used with pretty-print
  set total-score 0
  set score-last-run 0
  set messages-shown [0 0 0 0 0 0 ] ; initializes the number of help messages already shown to the student, by level

  set loops-at-zero int ( .3 / dt)  ; wait .3 sec before deciding that the car has stopped. 
  set countdown loops-at-zero
  set number-of-random-tries 0
  set level 1       ; start at level 1 (subsequently, levels were renamed as challenges. 
  set step 1        ; start at step 1
  set next-level level
  set next-step step
  set max-level 5   ; the number of levels in the game. Used to stop advancing beyond this level
  setup-game        ; setup for level 1 step 1
  show-target
  my-clear-output
  pretty-print "Challenge 1: Make the car stop in the middle of the red zone. Place the car on the ramp by clicking on it and dragging it."
  pretty-print "As you get better, the red target will get smaller."
  setup-data-export    ;;; used to define the structure of the exported data
  setup-new-run
  reset-ticks
  reset-timer
end

to define-window
  ; declare the location of the ramp window
  set ul min-pxcor + 2
  set ur max-pxcor - 2
  set vb 0
  set vt max-pycor - 2
end

to-report in-window? [u v]
  report ul < u and u < ur and vb < v and v < vt
end
  
to define-transforms    ; calculates m and b as in u=mx*x+bx v=my*y + by  
  let u-center (ul + ur) / 2
  let v-center (vb + vt) / 2
  set mx magnification
  set my magnification
  set bx (u-center - x-center * magnification)
  set by (v-center - y-center * magnification)
end

to support-mouse
  if not in-window? mouse-xcor mouse-ycor [stop] ; do nothing if the mouse is outside the ramp window
  if car-locked? [stop]                          ; if the car is locked, do nothing
    ; set car-x to the transform of the mouse's xcor, set car-y to be on the ramp for that x value
  if mouse-down? [ask cars [
      place-car ((mouse-xcor - bx) / mx)] ]       ; place the car on the track at the mouse x-coordinate
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;  Draw the ramp ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to draw-ramp
;  ask drawing-dots [die]                   ; erase any prior ramp 
  let object ramp                           ; object is a working version of ramp, a list of lists of x,y pairs 
  ; the ramp is drawn using drawing-dots
  let pair-zero []
  if not empty? object [                    ; pull off the first point
    set pair-zero first object
    set object bf object ]
  while [not empty? object][                ; repeat as long as there is a pair in object
    let pair-one first object
    set object bf object
    safe-connect pair-zero pair-one ramp-color magnification / 20 ; draw a line between pair-zero and pair-one
    set pair-zero pair-one ]
end

to safe-connect [p0 p1 c wide]                   ; draws a line between p0 and p1
  ; uses drawing-dots to connect p0 to p1 with a line of color c and width wide
  ; p0 and p1 are in physical units. 
  let u0 mx * (first p0) + bx
  let u1 mx * (first p1) + bx
  let v0 my * (last p0) + by
  let v1 my * (last p1) + by
  if u0 = u1 and v0 = v1 [stop] ; don't bother with points on top of each other
  ; assumes that u0 is in the window and that u1>u0 is either in the window or off the right edge. 
  let w 0                       ; the who of the left point
  create-drawing-dots 1 [       ; create the left end of the line and show it as a tick mark
    set size .1 * magnification 
    set shape "tick mark" set color black
    set heading 0
    setxy u0 v0 
    set w who]
  create-drawing-dots 1 [      ; make a label for the left-hand square dot a bit lower and to the right of the dot
    let x0 (u0 - bx) / mx 
    if x0 >= 0 [        ; label only non-negative physical values--these are on the floor
      set size .1
      set color yellow + 4.5  ; the same as the background
      set label-color black
      set label word (precision x0 2 ) " m"
      setxy u0 + 6 v0 - 6 ]] 
  create-drawing-dots 1 [     ; make the right end of the line--not a dot
    ht 
    if u1 > ur [set u1 ur]    ; if the right point is off the right edge, set it to the right edge
    setxy u1 v1
    create-link-with drawing-dot w [    ; draw a line between the two points 
      set thickness wide
      set color c ]]
end 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;  move the car  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to run-car
  ; using the starting position, move car forward only if running? is true
  if running? and not old-running? [   ; must be the first cycle 
    set old-running? true       
    set saved-starting-x car-x
    set start-height (precision height 2) ]        ; save the starting height
  
  ; begin the integration
  set time time + dt
  ask cars [
    let ch cos heading
    let sh sin heading
    let a 0
    let f 0    
    if car-x > 0 [ set f friction ] ;              ; ensure that the friction applies only on the floor
    ifelse car-speed > 0 
        [set a g * ( sh  - f * ch) ]               ; the acceleration to the right if the car is moving to the right
        [set a g * ( sh  + f * ch) ]               ; the acceleration to the right if the car is moving left
    let mid-speed car-speed + .5 * a * dt          ; estimate the speed mid-interval
    set car-x car-x + mid-speed * ch * dt          ; use the mid-interval speed to get the final x-value
    set car-speed mid-speed + .5 * a * dt          ; update the speed
    
    if car-x > 4.3 [ crash ]                       ; check whether the car reaches the right-hand edge. 
  
    ifelse abs (car-speed) > .005                 ; stop the run if it is at rest for more than countdown intervals
      [set countdown loops-at-zero]
      [set countdown countdown - 1 ]
    if countdown < 1 [
      handle-run-end ]
    place-car car-x]
end
  
to crash
  set car-speed 0                              ; crash into the right-hand wall. 
  my-clear-output
  pretty-print "Oops, you crashed the car!!"
  set shape "crash"                            ; we want to make this obvious because the p-space graph shows a break for runs that result in crashes
  let old-size size                            ; save the size
  set size 20 
  repeat 12 [wait .15 set size size + 10]
  wait .5
  set car-x 4.2
  set shape "car"
  set size old-size                            ; restore the size
end

to handle-run-end            ; This is called once when the car has not moved for a while, indicating that the run is over. Called by run-cars
  set final-position car-x
  set running? false         ; this stops the calculations and unlocks the sliders
  set ready-for-export? true ; require the next user action be analyzing the data
  my-clear-output               ; erase previous instructions for the user
  pretty-print "You can now analyze your data. Press the 'Analyze Data' button."
end

to capture-final-state
  if not starting? and not running? [
    set old-running? false
    set ready-for-export? true
    ; saves this experiment in an exportable form as a run
    ask cars [
      update-run-series (precision final-position 2) ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; put car on ramp ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to place-car [x]  ; in car context, puts the car on the track at x (in physical units)
  let mult 1 if level = 4 [set mult 1.4]                 ; enlarge car in level 4
  let off-mult 1 if level = 4 [set off-mult 1.2]         ; offset the more in level 4
  set size car-size * .01 * mult * magnification
  let old-offset car-offset
  set car-offset off-mult * car-offset
  set car-x x     ; update the variable car-x (needed in uv-of-car)
  let loc uv-of-car       ; get the [u v] coordinates of the car and set its heading
  let u first loc let v last loc
  ifelse in-window? u v   ; if the car is in the window
    [st setxy u v]        ; show it and place it
    [ht]
  set car-offset old-offset ; restore the offset
end

to-report uv-of-car ; in car context, reports the screen coordinates [u v] of the center of the car
  ; also sets the heading of the car and its car-y
  let disp car-offset * .01 * magnification        ; the displacement of the car center above the ramp
  let u mx * car-x + bx
  let info track-height ramp car-x     ; info contains the y and direction of the ramp at x
  let y first info 
  set car-y y
  set height y
  let v my * y + by
  set heading (last info) - 90
  set disp disp / cos heading
  report list u (v + disp)
end

to-report track-height [pairs x]    ; returns y(x) and angle: the height of the ramp at the car and dirction of the car
  ;  on a ramp that is defined by pairs, an ordered list of x,y lists (uses problem coordinates)
  if x < first first pairs [report list 0 90] ; if x is less than the first x or greater than the last, return zero
  if x > first last  pairs [report list 0 90]
  let i 1                             ; for the inteval between each pair defined by their x-values
  while [i < length pairs ][          ; find the two pairs that straddle x
    let x0 first item (i - 1) pairs 
    let x1 first item i pairs
    if x >= x0 and x <= x1 [ ; if x is not less than the previous x and not greater than the current one
      ; x must be between pair i-1 and i, so interpolate
      let y0 last item (i - 1) pairs
      let y1 last item i pairs
      if x0 = x1 [ report list (.5 * (y0 + y1)) 0] ; If the points are at the same x-value, return the average of the ys
      let direction atan (x1 - x0) (y1 - y0)
      report list (y0 + (x - x0) * (y1 - y0) / (x1 - x0)) direction]
    set i i + 1 ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;  Game functions ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
to setup-new-run
  if not waiting-for-setup? [data-export-log-event "User tried to setup a new run before analyzing data." "" "" ""
    stop]
  set waiting-for-setup? false
  set step next-step 
  set level next-level
  let endpoint 0
  data-export-log-event "User set up a new run." (create-run-parameter-list endpoint) "" ""
  set waiting-for-setup? false
  set waiting-for-start? true
  my-clear-output
  setup-game           ; sets up the various controls for this new step and level.
  show-target          ; shows the new target
  set time 0
  ask cars [
    set color red     
    if level = 3 [set color green]
    if level = 4 [set color blue]]
  if level = 5 [set saved-starting-x -.5]
  
  ask cars [
    place-car saved-starting-x 
    set car-speed 0]
  set running? false             ; the simulation is not running
  set old-running? false         ; used to trap the first cycle (probably redundant)
  data-export-clear-last-run
;  set waiting-for-setup? false  ; ignore this procedure if the next user action must be pressing the setup button
  show-target                    ; shows the target for this level and step
  pretty-print instructions 
  tick
end

to show-target   ; draws the target for the current level and step. 
  ; Must set step and level first, as well as target value and target radius (in problem space, e.g., meters)
  ; marker-1 and marker-2 were made in the initialize procedure and are always connected by a red line
  let y first track-height ramp target  ; track-height returns [y direction]
  ask marker marker-1 [
    let u mx * (target - target-radius) + bx
    let v my * y + by + 3
    setxy u v st ]
  ask marker marker-2 [
    let u mx * (target + target-radius) + bx
    let v my * y + by + 3
    setxy u v st ]
  ask marker marker-3 [         ; show a square indicator at the center of the target
    let u mx * target + bx
    let v my * y + by + 4.5
    setxy u v st ]
end

to start-run
  if waiting-for-setup? [
    data-export-log-event "User tried to start before pressing 'setup'." "" "" ""
    stop]  ; ignore this procedure if the next user action must be pressing the setup button
  if not waiting-for-start? [stop]
  if running? [data-export-log-event "User tried to start while running." "" "" ""
    stop]            ; ignore if running
  if car-x >= 0 [
    pretty-print "Place the car on the ramp." 
    data-export-log-event "User tried to start with car on the level floor." "" "" ""
    stop ] ; if the car is not on the ramp, stop
  if not data-saved? [
    if my-user-yes-or-no? "If you run now, you will lose data. Press the 'Analyze data' button to save your data." [stop]]
  set data-saved? false
  set waiting-for-start? false
  set ready-for-export? false
  set car-speed 0
  let endpoint 0
  set endpoint precision car-x 2
  data-export-log-event (word "User started the model with the following level and step: " level " " step ".") (create-run-parameter-list endpoint) "" ""
  set running? true
  set time 0
end

to get-next-step    ; determines whether the student stays at this step, goes up, or goes down and displays the score
                    ;   computes the next-step and next-level for setup-next-run
                    ; gives message about score and success and changes in step and level
                    ; but it does not actually report the new level and step--that happens in setup-next-run
   let upper-break 2 * max-score / 3  ; the minimum score to advance
   let lower-break max-score / 4  ; the minimum score to stay at this step

   if score-last-run > upper-break [  ; if the user did well
     my-clear-output
     pretty-print (word "Congratulations! You earned " score-last-run " points! You advance a step and the target gets smaller.")
     set next-step step + 1
     if next-step > n-steps [   ; if the user has completed all the steps in this level
       if level < max-level [           ; if this isn't the last level
         my-clear-output           ; overwrite the 'advance step' message
         pretty-print (word "Congratulations! You earned " score-last-run " points! You advance to a new challenge!!")
         pretty-print "Before going on, please open your lab notebook and record what you learned in this challenge."
         set freeze? true       ; freeze the game for a bit to force the user to use notebook
         set next-step 1 set next-level level + 1
         stop]
       if next-level >= max-level [          ; if the student is on the last level, keep at the highest step.  ; 
         set next-level max-level set next-step n-steps 
         if first-reward? [     ; say the following once only. More razmataz would be good.  
           my-clear-output         ; overwrite previous message
           pretty-print (word "Incredible!! You have completed the hardest challenge. You are a winner." )
           pretty-print "You can contine to earn points in this challenge, but first, jot down what you learned in your lab notebook."
           set first-reward? false
           set freeze? true]  ; freeze the game for a while
       ]]      ; if the student is on the last level, keep at the highest step.  ; 
     stop]
   
   if score-last-run > lower-break [      ; if the user did moderately well....
     my-clear-output
     pretty-print (word "OK! You earned " score-last-run " points. Try again.")
     pretty-print (word "You have to get " round upper-break " points to advance.")
     stop]
   
   if score-last-run <  lower-break [     ; if the user did poorly
     my-clear-output
     let m (word "Not so good. You score " score-last-run " points.")
     if step > 1 [set m (word m " Since your score was less than " round lower-break " you now get a easier target." )]
     pretty-print m
     set next-step step - 1 
     if step = 1 [set next-step 1]]
end

to setup-game     ; sets all the controls for the current level and step
  setup-game-level
  setup-game-step
end

to setup-game-level ; setup the game for the current level.
  set max-score  100   ; the maximum score for one run for all levels
  if level = 1 [
    set instructions "Place the car where you want it to start."
    if step = 1 [
      set instructions "Challenge 1: Make the car stop in the center of the red area by changing the car's starting position."
      set instructions word instructions " As you get better, the red target will get smaller."
      set instructions word instructions " When you press 'Analyze Data' your data is saved and graphed. The graph will help you later."
    ]
    set friction .18
    set old-friction friction
    set friction-locked? true
    set starting-position-locked? false
    set car-locked? false
    set starting-position-max -.9
    set starting-position-min -.9
    set n-steps  3   
    set target-radius-max .6 ; the distance between the center and edge of the target for step 1
    set target-radius-min .2 ; the distance for the highest step in this level
    set target-max 2.2    ; the target is placed at random between target-max and target-min
    set target-min 2.2]   ; to defeat random placement of the target, set min to max. 
  
  if level = 2 [
    set instructions ""
    if step = 1 [
      set instructions "Challenge 2: Make the car stop in the center of the red area by changing the car's starting position."
      set instructions word instructions " Watch out!! The red band now moves each trial."]
    set friction .18
    set old-friction friction
    set friction-locked? true
    set starting-position-locked? false
    set n-steps  4
    set car-locked? false
    set starting-position-max -.9
    set starting-position-min -.9
    set target-radius-max .5 ; the distance between the center and edge of the target for step 1
    set target-radius-min .2 ; the distance for the highest step in this level
    set target-max item (step - 1) [2.5 1.3 3.8 2 3.1]  ; move the target to predetermined places
    set target-min target-max - .5]   ; to defeat random placement of the target, set min to max. 
  
  if level = 3 [
    set instructions ""
    if step = 1 [set instructions "Challenge 3: Make a new car stop in the red area. This car has less friction."]
    set friction .08
    set car-mass 100
    set old-friction friction
    set starting-position-locked? false    
    set car-locked? false
    set n-steps  4
    set starting-position-max -.9
    set starting-position-min -.9
    set target-radius-max .5 ; the distance between the center and edge of the target for step 1
    set target-radius-min .25 ; the distance for the highest step in this level
    set target-max item (step - 1) [2.1 3.9 .6 3.2]  ; move the target to predetermined places
    set target-min target-max - .2]   ; to defeat random placement of the target, set min to max. 
  
  if level = 4 [
    set instructions ""
    if step = 1 [set instructions "Challenge 4: Make this heavier car stop in the center of the red area. This car is twice the mass of the last car."]
;    set instructions word instructions "\nYou will find it helpful to change the x-axis of the graph to ramp-height."
    set friction .18
    set car-mass 200
    set old-friction friction
    set starting-position-locked? false    
    set friction-locked? true
    set car-locked? false
    set n-steps  3
    set starting-position-max -.8
    set starting-position-min -.8
    set target-radius-max .5 ; the distance between the center and edge of the target for step 1
    set target-radius-min .2 ; the distance for the highest step in this level
    set target-max item (step - 1) [1.3 3.7 .5 3.2]  ; move the target to predetermined places
    set target-min target-max - .2]   ; to defeat random placement of the target, set min to max. 
  
  if level = 5 [
    set instructions ""
    if step = 1 [set instructions "Challenge 5: Now make the car stop in the center of the red area by changing the friction. "]
    set friction .18
    set car-mass 100
    set old-friction friction
;    set air-friction .2
    set starting-position-locked? true    
    set friction-locked? false
    set car-locked? true
    set n-steps 6
    set starting-position-max -.52
    set starting-position-min -.52
    set target-radius-max .5 ; the distance between the center and edge of the target for step 1
    set target-radius-min .2 ; the distance for the highest step in this level
    let tags [3.2 2.1 3.9 1.3 2.9 3.6 1.5 2.4 ]
    set target-max item (step - 1) tags  ; move the target to predetermined places
    if step = n-steps [set target-max one-of tags] ; if the user continues past the end, keep throwing items at random. 
    set target-min target-max - .3]   ; to defeat random placement of the target, set min to max. 
end

to setup-game-step   ; sets the values of controls that change with each step--the target and starting point widths
  set target random-between target-max target-min
  set target-radius target-radius-max + (target-radius-min - target-radius-max ) * (step - 1) / (n-steps - 1)
end
  
to-report random-between [a b]
  report a + random-float (b - a)
end

to pretty-print [mess]   ; prints the message mess with breaks at spaces and no more than line-max characters per line 
  if mess = 0 [stop]
  if empty? mess [stop]
  let line ""
  if length mess <= output-width [
    output-print mess stop]
  let i 0 let n -1
  while [i < output-width ][
    let ch item i mess
    if ch = " " [set n i ]    ; save the index of the space
    set i i + 1 ]             ; at this point n contains -1 indicating no spaces, or the index of the first space
  ifelse n = -1 
    [set line substring mess 0 output-width    ; print all output-width characters
      set mess substring mess output-width length mess ]
    [ifelse n = output-width 
      [set line substring mess 0 n 
        set mess substring mess n length mess]
      [set line substring mess 0 n 
        set mess substring mess (n + 1) length mess]]
  output-print line
  pretty-print mess
end

to update-score  ; called once by analyze-data
  ; computes the score for the most recent run and tests for random trials. 
  ; input is final-position, generated by run-cars
  ; output is score-last-run
  set score-last-run 0
  if abs (final-position - target) < target-radius [
    set number-of-random-tries number-of-random-tries - 1
    if number-of-random-tries < 0 [set number-of-random-tries 0]
;   use a scoring algorithm with a flat max that drops to zero when the user is off by target-radius: max*(1+cos (π*miss/radius)/2 
     set score-last-run .5 * max-score * (1 + cos (180 * abs (final-position - target) / target-radius))
     set score-last-run 5 * round (.2 * score-last-run )]   ; round to the nearest 5 points
  set total-score round (total-score + score-last-run)
  set score-last-run round score-last-run
  if abs (final-position - target) > 2 * target-radius [  ; very bad try, may be random
    set number-of-random-tries number-of-random-tries + 1
    if number-of-random-tries > 2 [
      pretty-print "It looks like you are just guessing. All the information that you need to hit the target is in the graph."
      wait 5]
    if number-of-random-tries > 3 [
      set number-of-random-tries 4
      pretty-print "You loose 100 points for gussing." 
      set total-score total-score - 100
      if total-score < 0 [set total-score 0 ]] 
    ]
    
  data-export-log-event (word "User score: " score-last-run ".") "" "" ""
  data-export-log-event (word "User max score:" max-score ".") "" "" ""
end             

to display-help-message 
  ; generates context-sensitive hints
  ; context is generated by step, level, and messages-shown, a list of the number of messages shown at level (item + 1)
  let number-shown-already item (level - 1) messages-shown
  set messages-shown replace-item (level - 1) messages-shown (number-shown-already + 1)
  let m "Sorry, no more hints are available."
  if level = 1  [
;    set number-shown-already number-shown-already mod 6
    if number-shown-already = 0 [
      set m "Before starting a run, move the car to where you think it will have enough energy to reach the center of the red target."
        set m word m " Try to get the antenna on the car near the red line in the center of the red target."]
    if number-shown-already = 1 [
      set m "Press the 'Start' button to start the car rolling down the ramp. "]
    if number-shown-already = 2 [
      set m "After a good score you advance by one step and the red target gets smaller. "]   
    if number-shown-already = 3 [
      set m "After each run, save your data by pressing the 'Analyze Data' button. " ] 
    if number-shown-already = 4 [
      set m "Before you can make a new run, you need to press the 'Setup New Run' button. "]    
    if number-shown-already = 5 [
      set m "The 'Setup New Run' button returns the car to its previous starting position. "]  
]
    
  if level = 2 [
    if number-shown-already = 0 [    
      set m "In this challenge, the red target moves around each run." ]    
    if number-shown-already = 1 [
      set m "Pay attention to the starting height above the floor. "]    
    if number-shown-already = 2 [
      set m "The graph can help you find the best place to start the car. "]    
    if number-shown-already = 3 [
      set m "Look carefully at the graph that shows starting height and distance traveled. "]
    if number-shown-already = 4 [
      set m "Clicking on the gear at the top right of the graph allows you to connect points. Try this."]
    if number-shown-already = 5 [
      set m "Under the gear is an option to draw and drag a line. This can be a big help. " ]
    if number-shown-already = 5 [
      set m "Expanding the scales on the graph can help you read values from the graph accurately."
      set m word m " Do this by dragging at the end of the scales. To undo this, use the option under the gear to show all the data."   ] 
    ]
    
  if level = 3 [
    if number-shown-already = 0 [    
      set m "For this challenge, the friction is lower than before." ] 
    if number-shown-already = 1 [    
      set m "Now when you save data, the points will trace out a different graph of distance against starting height." ] 
    if number-shown-already = 2 [    
      set m "Use the new graph of distance against starting height to predict starting positions at this challenge." ]]       
    if number-shown-already = 3 [    
      set m "One way to see the pattern is to clear out all the previous graph data before starting." ] 
  
  if level = 4 [
    if number-shown-already = 0 [    
      set m "For this challenge, you can change only the starting position of the car." ] 
    if number-shown-already = 1 [ 
      set m "Do you think a heavier car will travel further or less?"  ] 
    if number-shown-already = 2 [   
      set m "Note the friction value on the slider." ]  
    if number-shown-already = 3 [    
      set m "Hint: Think about Galileo's experiment at the Tower of Pisa." ]       ]

  if level = 5 [
    if number-shown-already = 0 [    
      set m "For this challenge, you cannot change the starting position of the car or the ramp height--you have to change friction." ]  
    if number-shown-already = 1 [    
      set m "To let the car go farther, do you think you should increase or decrease friction?"]
    if number-shown-already = 2 [    
      set m "Hint: Use the graph that has friction on the x-axis." ] 
    if number-shown-already = 3 [    
      set m "On the graph, you want to see only the points generated by challenge 5. "
      set m word m "You can do this by selecting only the last items in the table, the ones with starting position .38 m."]
    ]        
    
  pretty-print m         ; prints within the output box without breaking words. 
  ; update the messages-shown list (useful for logging)
  set messages-shown replace-item (level - 1) messages-shown (number-shown-already + 1)
  ; set number-of-hints reduce + messages-shown
  data-export-log-event (word "User received the message " m) "" "" ""
end

to-report score-display
  ifelse not (level = 1 and step = 1)
    [report (word Score-last-run " out of " max-score)]
    [report ""]
end

to analyze-data ;
  if not ready-for-export? [data-export-log-event "User tried to analyze data before a run." "" "" ""
    stop]    
  my-clear-output
  capture-final-state
  update-score         ; computes and displays the score  
  get-next-step        ; computes next-step and next-level and prints result, but doesn't display the new level/step
  if next-level = 1 and next-step = 1 [
    pretty-print "Data saved. Do you see the new point on the graph?"
    pretty-print "Now setup an new run by pressing the 'Setup New Run' button."]
  set ready-for-export? false
  set data-saved? true
  set waiting-for-setup? true
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Start of data-export methods ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; *** setup-data-export
;;;
;;; Structure definitions for setup-data-export method:
;;;
;;; computational-inputs and representational-inputs
;;;   label, units, min, max, visible
;;;
;;;   label: string
;;;   units: string
;;;   min: number
;;;   max: number
;;;   visible: boolean
;;;
;;;   alternate form when value of units is "categorical"
;;;   label units [categorical-type1 categorical-type2 ...]  visible
;;;
;;; computational-outputs
;;;   label, units, min, max, visible
;;;
;;;   label: string
;;;   units: string
;;;   min: number
;;;   max: number
;;;   visible: boolean
;;;
;;; student-inputs
;;;   label, unit-type
;;;
;;;   label: string
;;;   unit-type: string
;;;
;;; model-information
;;;   name, filename, version
;;;
;;; time-series-data (an array of lists)
;;;   label, units, min, max
;;;
;;; Edit setup-data-export and call when your model is setup
;;;

to setup-data-export
  let computational-inputs [       ; students can adjust
    [ "Challenge" "" 1 5 true ]
    [ "Step" "" 1 8 true ]
    [ "Start height" "m" 0 1.5 true ]
    [ "Friction" "" 0 .3 true ]
    [ "Mass" "g" 100 200 true ]]
  let representational-inputs [ ]  ; student analysis of run
  let computational-outputs [      ; calculated
    [ "End distance" "m" 0 6 true ]]
  let student-inputs [ ]           ; other student actions during analysis
  let model-information [          ; 
    [ "ramp" "RampGame.v5b.nlogo" "Jan-7-2014" ] ]
  let time-series-data [
;    [ "Time" "s" 0 0.1 ]           ; Check
;    [ "Distance" "m" 0 0.6 ]
;    [ "Height" "m" -10 10 ]
;    [ "Speed" "m/s" -10 10 ]
    ]
  let setup (list computational-inputs representational-inputs computational-outputs student-inputs model-information time-series-data)
  data-export-initialize setup
end


;;;
;;; update-run-series 
;;;    call once at the end of a run
;;;    pass in any needed values as arguments if they are not accessible as global variables
;;;

to update-run-series [endpoint]    
  let computational-inputs     (list level step start-height friction car-mass) 
  let representational-inputs []
  let computational-outputs   ( list endpoint )
  let student-inputs          []
  let run-series-data ( list computational-inputs representational-inputs computational-outputs student-inputs )
  data-export-update-run-series run-series-data
  data-export-log-event "User explorted the model." (create-run-parameter-list endpoint) "" ""
end

to-report create-run-parameter-list [endpoint]
  report (list start-height friction endpoint car-mass)
end

;;;
;;; update-data-series [ data-series ]
;;;    call once at the end of a run
;;;    data series is a list: [time distance height speed] generated each time the display is updated
;;;    pump 
;;;    pass in any needed values as arguments if they are not global variables
;;;

;to update-data-series 
;  data-export-update-data-series data-series
;end

;;;
;;; update-inquiry-summary [ inquiry-summary ]
;;;
;;; inquiry-summary is an optional custom string generated by the application
;;;

;;;;to update-inquiry-summary
;;;;  data-export-update-inquiry-summary []
;;;;end

;;;
;;; To test in NetLogo:
;;;
;;;
;;; After running the model call the method data-export-make-model-data:
;;; 
;;;   data-export-make-model-data
;;;
;;; This will update the global variable: data-export-model-data
;;;
;;; Now print data-export-model-data which contains the JSON data available for export:
;;;
;;;   data-export-make-model-data print data-export-model-data
;;;
;;;
;;; end of data-export methods
;;;
@#$#@#$#@
GRAPHICS-WINDOW
10
28
643
475
150
100
2.07
1
10
1
1
1
0
0
0
1
-150
150
-100
100
0
0
0
ticks
30.0

BUTTON
10
10
112
54
Go
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
114
253
211
287
Setup New Run
setup-new-run
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
16
219
211
253
Start
Start-run
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
298
211
331
Friction
Friction
0
.4
0.18
.005
1
NIL
HORIZONTAL

TEXTBOX
21
334
210
362
This slider sets the friction of the car on the floor.
10
0.0
1

MONITOR
111
10
227
55
Height above Floor
word precision Height 2 " m"
17
1
11

MONITOR
226
10
351
55
Distance to the right
word precision car-x 2 " m"
17
1
11

MONITOR
18
375
103
424
Total Score
Total-Score
17
1
12

MONITOR
102
375
211
424
Score last run
score-display
17
1
12

MONITOR
18
423
102
472
Challenge
(word Level " of " max-level)
17
1
12

MONITOR
102
423
211
472
Step
(word Step " of " n-steps)
17
1
12

BUTTON
16
253
113
287
Analyze data
analyze-data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
349
10
446
55
Car Mass
word car-mass " g"
17
1
11

MONITOR
445
10
551
55
Friction
Friction
17
1
11

BUTTON
549
10
643
55
Help
display-help-message
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
212
219
636
471
13

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
true
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

ball
false
0
Circle -7500403 true true 0 0 300

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

bus
true
0
Polygon -7500403 true true 15 206 15 150 15 120 30 105 270 105 285 120 285 135 285 206 270 210 30 210
Rectangle -16777216 true false 36 126 231 159
Line -7500403 true 60 135 60 165
Line -7500403 true 60 120 60 165
Line -7500403 true 90 120 90 165
Line -7500403 true 120 120 120 165
Line -7500403 true 150 120 150 165
Line -7500403 true 180 120 180 165
Line -7500403 true 210 120 210 165
Line -7500403 true 240 135 240 165
Rectangle -16777216 true false 15 174 285 182
Circle -16777216 true false 48 187 42
Rectangle -16777216 true false 240 127 276 205
Circle -16777216 true false 195 187 42
Line -7500403 true 257 120 257 207

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

button
true
5
Rectangle -7500403 true false 30 75 285 225
Rectangle -10899396 true true 45 90 270 210

car
true
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58
Rectangle -7500403 true true 150 0 165 60

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

crash
true
0
Polygon -1184463 true false 135 30 120 135 15 75 90 165 30 255 120 210 150 315 165 195 300 225 195 165 240 60 150 120
Polygon -2674135 true false 135 135 90 75 105 150 30 135 120 180 45 210 120 195 195 270 150 180 240 150 150 150 165 45

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

engine
true
0
Rectangle -7500403 true true 30 105 240 150
Polygon -7500403 true true 240 105 270 30 180 30 210 105
Polygon -7500403 true true 195 180 270 180 300 210 195 210
Circle -7500403 true true 0 165 90
Circle -7500403 true true 240 225 30
Circle -7500403 true true 90 165 90
Circle -7500403 true true 195 225 30
Rectangle -7500403 true true 0 30 105 150
Rectangle -16777216 true false 30 60 75 105
Polygon -7500403 true true 195 180 165 150 240 150 240 180
Rectangle -7500403 true true 135 75 165 105
Rectangle -7500403 true true 225 120 255 150
Rectangle -16777216 true false 30 203 150 218

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
false
0
Rectangle -7500403 true true 150 0 165 150

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tick mark
true
0
Rectangle -7500403 true true 135 90 165 240

tiny dot
true
0
Circle -7500403 true true 135 135 30

train
false
0
Rectangle -7500403 true true 30 105 240 150
Polygon -7500403 true true 240 105 270 30 180 30 210 105
Polygon -7500403 true true 195 180 270 180 300 210 195 210
Circle -7500403 true true 0 165 90
Circle -7500403 true true 240 225 30
Circle -7500403 true true 90 165 90
Circle -7500403 true true 195 225 30
Rectangle -7500403 true true 0 30 105 150
Rectangle -16777216 true false 30 60 75 105
Polygon -7500403 true true 195 180 165 150 240 150 240 180
Rectangle -7500403 true true 135 75 165 105
Rectangle -7500403 true true 225 120 255 150
Rectangle -16777216 true false 30 203 150 218

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
true
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
