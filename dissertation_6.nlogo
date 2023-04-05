extensions [ array ]

breed [ households household ]
breed [ cbds cbd ]
;breed [ centralhomes centralhome ]
;breed [ sprawlhomes sprawlhome ]

;;;;;;;;notes - need to create (1) housing market, (2) neighborhood structure, (3) district structure, (4)

globals [
;  total-centralhomes-to-make
;  total-sprawlhomes-to-make
;  num-centralhomes
;  num-sprawlhomes
  owner-reps
  renter-reps
  city-dataset
  roads ;; from Eckerd, Campbell, Kim
  land
  org-radius
  equal-population-error ;; percent increase/decrease to consider populations equal enough
  number-dead
  number-displaced
  households-to-spawn
  monthly-interest-rate
  ]

cbds-own
[
  is-cbd
]

households-own
[
  age
  money
  income
  incomePrev
  monthly-income
  consumption
  monthly-consumption
  hh-size
  race
  sex
  ethnicity-white?
  ethnicity-black?
  preference
  net-income
  net-monthly-income
  my-home
  myRental
  home-xy
  hasChild?
  married?
  ageChild
  move-propensity-var
  move-propensity
  collegedegree?
  owner
  renter
  professional?
  hh-district
  myrooms
  nearest-cbd
  distance-to-cbd
  joining-propensity
  ideology
  liberal?
  vote-ban-neighborhood-var
  vote-ban-neighborhood
  vote-supply-increase-var
  vote-supply-increase
  mydistrict
  seller?
  qualifying-patches
  candidate-patches
  mover-renter
  my-target-house
  closest-target
  quality-target
  cheapest-target
  my-target-rental
  closest-rental-target
  quality-rental-target
  cheapest-rental-target
  preference-p-q-d
]

patches-own
[
  is-home?
  district  ;;district number
  cost
  down-payment
  mortgage
  mortgage-payment
  home-size
  rent
  rooms
  occupied?
  onMarket?
  owner-occupied
  rental
  my-owner
  my-renter
  isRental
  id
  road
  roaddist ;; from Eckerd, Campbell, Kim
  quality ;; from Eckerd, Campbell, Kim
  utility ;;  from Eckerd, Campbell, Kim
  closest-cbd
  distance-cbd
  prop-min
  prop-maj
  job-location
]

;; from https://stackoverflow.com/questions/23698008/divide-netlogo-world-into-several-random-parts
to grow-districts ;[ num-districts ]
  let region-num 0
  ask n-of num-districts patches [
    set pcolor item region-num base-colors
    set region-num region-num + 1
  ]
  while [ any? patches with [ pcolor = black ] ] [
    ask patches with [ pcolor != black ] [
      ask neighbors with [ pcolor = black ] [ set pcolor [ pcolor ] of myself ]
    ]
  ]
end

to setup
  ca
  reset-ticks
  setup-plots
  ;resize-world -32 32 -32 32
  set org-radius 3
  grow-districts
  set-default-shape households "person"
;  set total-centralhomes-to-make (round homes * (density-percentage / 100)) ; from Yust
;  set total-sprawlhomes-to-make (round homes * (1 - (density-percentage / 100)))
  generate-cbds
;  create-centralhomes total-centralhomes-to-make  ;;uniformly distribute rest of dems (total/(2^n))
;  [
;    set color blue
;    setxy random-xcor random-ycor
;    set shape "house"
;  ]
;  create-sprawlhomes total-sprawlhomes-to-make
;  [
;    set color red
;    setxy random-xcor random-ycor
;    set shape "house"
;  ]
;  while [ any? patches with [ count sprawlhomes-here >= 0.25 * (count sprawlhomes) / num-districts ] ] [  ;;make sure cities aren't too dense to make districts
;    ask sprawlhomes [
;      rt random 360 fd random 3
;    ]
;  ]
  create-households num-households [ setxy random-xcor random-ycor ]
  setup-patches
  setup-households
  ask households [
    choose-house
  ]
end

to generate-cbds
  let cbd-num 1
  repeat num-cbds [
    let center-x random-xcor / 1.5 ;;keep cities away from edges
    let center-y random-ycor / 1.5
;    ask patch center-x center-y [
;      while [ any? cbds in-radius (4 * (0.9) ^ (cbd-num)) ] [ ;;check for other cities nearby
;        set center-x random-xcor / 1.5
;        set center-y random-ycor / 1.5
;      ]
;    ]
      create-cbds 1 [
      setxy center-x center-y
      set shape "star"
      set color white
      set size 0.85 ^ (cbd-num) ;;reduce the size of the star to indicate smaller cities
    ]
  ]
end

to setup-households
  ask households
    [ set ideology round random-normal-in-bounds 5 2 1 7 ; 1-7 from extremely conservative to extremely liberal (based on Hankinson 2019)
      set liberal? ifelse-value ( ideology > 4 ) [ 1 ] [ 0 ]
      set age random-poisson 38
      set sex random 1 ; 1 = male per Hankinson 2019
      set money round random-exponential-in-bounds 50000 0 1000000
      set collegedegree? random 2
      set professional? random 2
      set income round random-exponential-in-bounds 64324 12000 1000000
      set monthly-income round income / 12
      set consumption round random-normal-in-bounds .4 .05 .2 .7 * income ; changed from fixed parameter to sampled from distribution
      set monthly-consumption round consumption / 12
      set hh-size random 6 + 1
      set net-income income - consumption
      set net-monthly-income monthly-income - monthly-consumption
      ifelse hh-size = 1 [ set hasChild? 0 ] [ if-else hh-size > 2 [ set hasChild? 1 ] [ set hasChild? one-of [ 1 0 ] ] ]
      ifelse hh-size > 1 [ set married? 1 ] [ set married? 1 ]
      set nearest-cbd min-one-of cbds [ distance myself ]
      set closest-cbd min-one-of cbds [ distance myself ]; in-radius 9
;      set distance-to-cbd distance nearest-cbd
      set move-propensity-var ( random-float 1 + ( age * .0339 ) + ( age ^ 2 * -.0009 ) + ( hasChild? * -.2564 ) + ( married? * -.1655) + ( owner * -1.4814 ) + ( renter * .1180 ) + ( income * 0.00000280) ) ; propensity weights based on odds ratios from Clark 2013
      set move-propensity move-propensity-var / ( 1 + move-propensity-var )
      set joining-propensity random-float .5 + ( owner * .25 ) ; From DiPasquale and Glaeser 1999
      set ethnicity-white? random 1
      set ethnicity-black? ifelse-value ( ethnicity-white? = 1 ) [ 0 ] [ 1 ]
      set vote-ban-neighborhood-var ( random-float 1 + ( .08 * owner ) + ( -.03 * liberal? ) + ( ln income * -.01 ) + ( ethnicity-white? * -.05 ) + ( age * -.0004 ) + ( sex * -.02 ) ) ; from Hankinson 2019 Table B.4. Sex 1 = Male
      set vote-ban-neighborhood vote-ban-neighborhood-var / ( 1 + vote-ban-neighborhood-var )
      set vote-supply-increase-var ( random-float 1 + ( -.25 * owner ) + ( .04 * liberal? ) + ( ln income * -.02 ) + ( ethnicity-white? * -.09 ) + ( age * -.001 ) + ( sex * .06 ) )
      set vote-supply-increase vote-supply-increase-var / ( 1 + vote-supply-increase-var )
      set preference-p-q-d one-of ["price" "quality" "distance"]
      set job-location one-of cbds
      set owner 0
      set renter 0
    ]
end

to form-organizations
  ask households
  [
    ifelse joining-propensity >= joining-threshold
    [ ask other households in-radius org-radius [ create-link-from myself ] ]
    [ ]
  ]
end

to-report random-normal-in-bounds [mid dev mmin mmax]
  let result random-normal mid dev
  if result < mmin or result > mmax
    [ report random-normal-in-bounds mid dev mmin mmax ]
  report result
end

to-report random-gamma-in-bounds [shpe scale mmin mmax]
  let result random-gamma shpe scale
  if result < mmin or result > mmax
    [ report random-gamma-in-bounds shpe scale mmin mmax ]
  report result
end

to-report random-exponential-in-bounds [mid mmin mmax]
  let result random-exponential mid
  if result < mmin or result > mmax
    [ report random-exponential-in-bounds mid mmin mmax ]
  report result
end

to-report random-poisson-in-bounds [gamma mmin mmax]
  let result random-poisson gamma
  if result < mmin or result > mmax
    [ report random-exponential-in-bounds gamma mmin mmax ]
  report result
end

to setup-patches
  set roads patches with [ ;; from Eckerd, Campbell, Kim lines 288 - 306
    remainder pxcor 10 = 0 or remainder pycor 10 = 0 ]
  ask roads
  [
    set pcolor white
    set road 1
  ]

  set land patches with [ pcolor != white ]
  ask land
  [
    set roaddist min [distance myself + .01] of roads
  ]

  ask n-of homes land
  [   set is-home? one-of [ true false ]
    if-else is-home? = true
    [
      set rooms round random-exponential int 3
      set home-size random-normal-in-bounds 1575 100 500 4000
      set onMarket? TRUE
      set cost random-normal 173000 43000 ;; from Eckerd, Kim, Campbell 2019
      ;;set cost ceiling cost * 100
      set rent mortgage-payment + mortgage-payment * rent-premium
      set down-payment cost * down-payment-rate
      set mortgage-payment (cost - down-payment) * (((interest-rate / 12) * (1 + interest-rate / 12) ^ 360) / (((1 + interest-rate / 12) ^ ( interest-rate / 12 ) - 1))) ; Amortization formula
      set owner-occupied 0
      set rental 0
      set my-owner nobody
      set my-renter nobody
;      set closest-cbd min-one-of cbds [distance myself]
;      set distance-cbd [ distance myself ] of closest-cbd
      set quality random-normal 50 15
    ]
    []
    ]
end

to go
  ask households [
    choose-house
;    designate-owner-renter
;    type "closest patch" show closest-target
;    type "quality" show [quality] of quality-target
;    type "quality patch" show quality-target
  ]
  updateLifecycle
  form-organizations
  death
  spawn-households
  tick
  if ticks > 0 and ticks mod 1 = 0 [ ; <--- this is the important line https://stackoverflow.com/questions/37666498/how-to-create-new-generation-of-turtles-every-10-ticks
    updateImmigration
    ]
end

to choose-house
  ask households
  [
    if not any? households with [my-home != nobody] [
      stop ] ; if all houses have been bought, stop the simulation
    ifelse any? patches with

    [
      is-home? = true
      and down-payment <= [money] of myself
      and mortgage-payment <= [income] of myself * 3
      and onMarket? = TRUE
      and my-owner = nobody
    ]

    and my-home = nobody

    [
      set my-target-house patches with
      [
        is-home? = true
        and [money] of myself >= down-payment
        and mortgage-payment <= ([income] of myself * .3)
        and onMarket? = TRUE and my-owner = nobody
      ]

      set closest-target min-one-of my-target-house
      [
        distance
        [ job-location ]
        of myself
      ]

      set quality-target max-one-of my-target-house
      [ quality ]

      set cheapest-target min-one-of my-target-house
      [ cost ]

      ifelse preference-p-q-d = "distance"
      [
        move-to closest-target
      ]
      [
        ifelse preference-p-q-d = "quality"
        [
          move-to quality-target
        ]
        [
          move-to cheapest-target
        ]
      ]

      set owner 1
      set my-home  patch-here
      set mydistrict pcolor
      set occupied? TRUE
      set onMarket? FALSE
      set my-owner households-here
    ]

    [
      ifelse any? patches with
      [
        is-home? = true
        and rent <= ([income] of myself * .3)
        and onMarket? = TRUE
        and not any? turtles-here
      ]

      [
        set my-target-rental patches with
        [
          is-home? = true
          and rent <= ([income] of myself * .3)
          and onMarket? = TRUE
          and not any? turtles-here
        ]
        set closest-target min-one-of my-target-rental
        [ distance [job-location] of myself ]
        set quality-target max-one-of my-target-rental
        [ quality ]
        set cheapest-target min-one-of my-target-rental
        [ cost ]
        ifelse preference-p-q-d = "distance"
        [
          move-to closest-target
        ]
        [
          ifelse preference-p-q-d = "quality"
        [
          move-to quality-target
        ]
        [
          move-to cheapest-target
        ]
      ]
        set owner 1
        set myRental  patch-here
        set mydistrict pcolor
        set occupied? TRUE
        set onMarket? FALSE
        set my-renter households-here
      ]
      [
        set number-displaced number-displaced + 1
        die
      ]
    ]
  ]
end

;to choose-house
;  ifelse any? patches with [ is-home? = true and [money] of myself >= down-payment and mortgage-payment <= ([income] of myself * .3) and onMarket? = TRUE and myOwner = nobody ]
;  [ set my-target-house one-of patches with [ is-home? = true and [money] of myself >= down-payment and mortgage-payment <= ([income] of myself * .3) and onMarket? = TRUE and myOwner = nobody ] ;; took out not any? turtles-here
;  set closest-target min-one-of my-target-house [ distance [job-location] of myself ]
;  set quality-target max-one-of my-target-house [ quality ]
;  set cheapest-target min-one-of my-target-house [ cost ]
;  if preference-p-q-d = "price" [ set myHome cheapest-target set money money - down-payment ]
;  if preference-p-q-d = "distance" [ set myHome closest-target set money money - down-payment ]
;    if preference-p-q-d = "quality" [ set myHome quality-target set money money - down-payment ]
;;  [
;;    ifelse preference-p-q-d = "quality" [ set myHome quality-target set money money - down-payment ]
;;    [
;;      set myHome closest-target set money money - down-payment
;;    ]
;;  ]
;  set onMarket? FALSE
;    set owner 1
;    set renter 0
;  ]
;  [
;  ifelse my-target-house = no-patches [
;    set my-target-rental ( patches with [ is-home? = true and rent <= ([income] of myself * .3) and onMarket? = TRUE and not any? turtles-here])
;  set closest-rental-target min-one-of my-target-rental [ distance [job-location] of myself ]
;  set quality-rental-target max-one-of my-target-rental [ quality ]
;  set cheapest-rental-target min-one-of my-target-rental [ cost ]
;  if preference-p-q-d = "price" [ set myRental cheapest-rental-target ]
;  if preference-p-q-d = "distance" [ set myRental closest-rental-target ]
;  if preference-p-q-d = "quality" [ set myRental quality-rental-target ]
;;  [
;;    ifelse preference-p-q-d = "quality" [ set myRental quality-target ]
;;    [
;;      set myRental closest-target
;;    ]
;;  ]
;    set onMarket? FALSE
;    set owner 0
;    set renter 1
;  ]
;    [if my-target-house = no-patches and my-target-rental = no-patches [
;    set number-displaced number-displaced + 1
;      die ]
;    ]
;  ]
;  set hh-district pcolor
;end

;to designate-owner-renter
;  ifelse myHome = nobody or myHome = 0 [ set owner 0 ] [ set owner 1 ]
;  ifelse myRental = nobody or myHome = 0 [ set renter 0 ] [ set renter 1 ]
;end

;to go-home
;  ask households [
;    ifelse my-home != nobody
;    [ move-to my-home ]
;    [ ifelse myRental != nobody
;      [ move-to myRental ]
;      []
;    ]
;    set mydistrict pcolor
;  ]
;end

to put-house-on-market
  ask households
  [ if owner = true and renter = false and move-propensity > .5
    [ set seller? true ]
    if seller? = true
    [ set onMarket? true ]
    if owner = false and renter = true and move-propensity > .5
    [ set mover-renter true ]
    if mover-renter = true
    [ set onMarket? true ]
  ]
end

to make-offer
  ask households
  [ ifelse move-propensity > .5
    [ set qualifying-patches land with
      [
        prop-min < ( 1 - maj-similarity-preference ) and not any? households-here and down-payment < [money] of myself and mortgage-payment < [net-monthly-income] of myself
      ]
    ] ;; from Eckerd, Campbell, and Kim
    [ set qualifying-patches candidate-patches with [ is-home? = 1 and prop-min < ( 1 - maj-similarity-preference ) ] ]

  ] ;; from Eckerd, Campbell, and Kim

end

; update income of households
to updateIncome
  ask households
  [
   let growth getGrowth age
   let transitoryIncome incomePrev + income * (growth + 0.02) + random-normal 0 0.032
   set incomePrev transitoryIncome
   set income transitoryIncome + random-normal 0 0.037
    ]
end

; get income growth rate of households
to-report getGrowth [ages]
  let growth 0
  ifelse ages < 29 [
    set growth 0.1
  ][
   ifelse ages < 59 [
     set growth 0.05
   ][
    ifelse ages < 69 [
      set growth -0.05
    ][
    set growth 0
    ]]]
  report growth
end

;; add new houses on the market in each period if household wishes to move or if debt payments too high
;to newListings
;  ask households [
;    let ageInt (age - age mod 10 - 20) / 10
;    let probMove move-propensity
;    let rand random-float 1
;    let preferred preferredExp income
;    if ((rand < probMove or income - (interestRate * debt) < item (year - 1) consumptionBudget / 2) and myHome != nobody) [
;      ask myHome [
;        set onMarket 1
;        set listingPrice getListing self
;      ]
;     ]
;  ]
;end

to death
  ask households
  [ if floor (ticks mod 12) = 0
    [ set age age + 1 ]
    if age > 85
    [ set number-dead number-dead + 1 die ]
  ]
end

to spawn-households
  set households-to-spawn num-households - count households + ( growth-rate * (num-households - count households))
  create-households households-to-spawn
end

to updateLifecycle ;; Adapted from Usvedt
  ask households
  [ if ticks > 0 and ticks mod 12 = 0
    [
      set age age + 1
      let probChild 0
      ifelse age <= 24
      [ set probChild 0.06 ]
      [ ifelse age <= 29
        [ set probChild 0.13 ]
        [ ifelse age <= 34
          [ set probChild 0.12 ]
          [ ifelse age <= 39
            [ set probChild 0.05 ]
            [ set probChild 0 ]
          ]
        ]
      ]
    let draw random 100
    if draw < probChild * 100 [
      set hasChild? 1
      set ageChild -1
    ]
    if hasChild? = 1 [
      set ageChild ageChild + 1
      set hh-size hh-size + 1
    ]
    if ageChild > 18 [
      set hasChild? 0
    ]
    set income income + income * .02
    ]
  ]
end

to updateImmigration
  create-households count households * .01 [
    set ideology round random-normal-in-bounds 5 2 1 7 ; 1-7 from extremely conservative to extremely liberal (based on Hankinson 2019)
      set liberal? ifelse-value ( ideology > 4 ) [ 1 ] [ 0 ]
      set age random-poisson 38
      set sex random 1 ; 1 = male per Hankinson 2019
      set money round random-exponential-in-bounds 50000 0 1000000
      set collegedegree? random 2
      set professional? random 2
      set income round random-exponential-in-bounds 64324 12000 1000000
      set monthly-income income / 12
      set consumption .5 * income
      set monthly-consumption consumption / 12
      set hh-size random 6 + 1
      set net-income income - consumption
      set net-monthly-income monthly-income - monthly-consumption
      ifelse hh-size = 1 [ set hasChild? 0 ] [ if-else hh-size > 2 [ set hasChild? 1 ] [ set hasChild? one-of [ 1 0 ] ] ]
      ifelse hh-size > 1 [ set married? 1 ] [ set married? 1 ]
      set nearest-cbd min-one-of cbds [ distance myself ]
      set closest-cbd min-one-of cbds [ distance myself ]; in-radius 9
;      set distance-to-cbd [ distance myself ] of nearest-cbd
      set move-propensity-var ( random-float 1 + ( age * .0339 ) + ( age ^ 2 * -.0009 ) + ( hasChild? * -.2564 ) + ( married? * -.1655) + ( owner * -1.4814 ) + ( renter * .1180 ) + ( income * 0.00000280) ) ; propensity weights based on odds ratios from Clark 2013
      set move-propensity move-propensity-var / ( 1 + move-propensity-var )
      set joining-propensity random-float 1 + ( owner * .25 ) ; From DiPasquale and Glaeser 1999
      set ethnicity-white? random 1
      set ethnicity-black? ifelse-value ( ethnicity-white? = 1 ) [ 0 ] [ 1 ]
      set vote-ban-neighborhood-var ( random-float 1 + ( .08 * owner ) + ( -.03 * liberal? ) + ( ln income * -.01 ) + ( ethnicity-white? * -.05 ) + ( age * -.0004 ) + ( sex * -.02 ) ) ; from Hankinson 2019 Table B.4. Sex 1 = Male
      set vote-ban-neighborhood vote-ban-neighborhood-var / ( 1 + vote-ban-neighborhood-var )
      set vote-supply-increase-var ( random-float 1 + ( -.25 * owner ) + ( .04 * liberal? ) + ( ln income * -.02 ) + ( ethnicity-white? * -.09 ) + ( age * -.001 ) + ( sex * .06 ) )
      set vote-supply-increase vote-supply-increase-var / ( 1 + vote-supply-increase-var )
    ]
end

to-report supply-vote
 ifelse ( ticks > 0 and ticks mod 12 = 0 )
    [report (count households with [ vote-supply-increase-var > .5 ] * sum [ hh-size ] of households - sum [ hasChild? ] of households)/(count households * sum [ hh-size ] of households - sum [ hasChild? ] of households) ]
  [report 0]; where "" is an empty placeholder text that you may ignore.]
end

to-report neighborhood-ban-vote
 ifelse ( ticks > 0 and ticks mod 12 = 0 )
        [report count households with [ vote-ban-neighborhood > .5 ] * ( sum [ hh-size ] of households - sum [ hasChild? ] of households ) ]
  [report 0]; where "" is an empty placeholder text that you may ignore.]
end

to do-plots
  ;set-current-plot-pen "ban-votes"
  ;set-current-plot-pen "neighborhood-ban-vote"
  ;plot sum neighborhood-ban-vote
end


;; ADD: tick death counter
;; then you can run sensitivity analysis

@#$#@#$#@
GRAPHICS-WINDOW
676
-15
1329
639
-1
-1
9.9231
1
10
1
1
1
0
1
1
1
-32
32
-32
32
0
0
1
ticks
30.0

BUTTON
5
45
68
78
NIL
go
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
5
7
71
40
NIL
setup
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
5
85
183
118
homes
homes
0
1000
477.0
1
1
NIL
HORIZONTAL

SLIDER
7
164
181
197
density-percentage
density-percentage
0
100
44.0
1
1
NIL
HORIZONTAL

SLIDER
7
204
179
237
num-cbds
num-cbds
0
3
3.0
1
1
NIL
HORIZONTAL

SLIDER
7
244
179
277
num-districts
num-districts
0
14
14.0
1
1
NIL
HORIZONTAL

SLIDER
7
124
179
157
num-households
num-households
0
1000
661.0
1
1
NIL
HORIZONTAL

SLIDER
7
284
179
317
rent-premium
rent-premium
0
1
0.14
.01
1
NIL
HORIZONTAL

SLIDER
7
324
185
357
down-payment-rate
down-payment-rate
0
.3
0.2
.01
1
NIL
HORIZONTAL

SLIDER
7
364
179
397
interest-rate
interest-rate
0
.15
0.025
.001
1
NIL
HORIZONTAL

SLIDER
7
404
179
437
joining-threshold
joining-threshold
0
1
0.5
.01
1
NIL
HORIZONTAL

BUTTON
80
46
143
79
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
450
195
650
345
ban-votes
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"ban-votes" 1.0 0 -16777216 true "plot neighborhood-ban-vote" "plot neighborhood-ban-vote"

PLOT
240
355
440
505
supply-votes
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"supply-votes" 1.0 0 -16777216 true "" "plot supply-vote"

SLIDER
7
444
179
477
growth-rate
growth-rate
0
1
0.01
.01
1
NIL
HORIZONTAL

MONITOR
240
10
298
55
owners
count households with [ owner = 1 ]
0
1
11

MONITOR
240
55
298
100
renters
count households with [ renter = 1 ]
0
1
11

MONITOR
295
10
358
55
owner %
(count households with [ owner = 1 ] / (count households)) * 100
2
1
11

MONITOR
295
55
358
100
renter %
(count households with [ renter = 1 ] / (count households)) * 100
2
1
11

SLIDER
7
484
219
517
maj-similarity-preference
maj-similarity-preference
0
1
0.5
.01
1
NIL
HORIZONTAL

SLIDER
7
524
219
557
min-similarity-preference
min-similarity-preference
0
100
63.0
1
1
NIL
HORIZONTAL

PLOT
450
355
650
505
owner-count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count households with [ owner = 1 ]"

PLOT
240
515
440
665
households-displaced
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot number-displaced"

MONITOR
355
10
472
55
Mean Home Price
(sum [cost] of patches with [ is-home? = TRUE ]) / (count patches with [ is-home? = TRUE ])
2
1
11

MONITOR
355
55
470
100
Mean Wealth
mean [money] of households
2
1
11

MONITOR
355
100
470
145
Mean Income
mean [income] of households
2
1
11

MONITOR
240
100
355
145
Vacant Homes
count patches with [is-home? = TRUE and my-owner = nobody and my-renter = nobody]
2
1
11

MONITOR
240
145
355
190
Total Homes
count patches with [is-home? = TRUE]
0
1
11

PLOT
240
195
440
345
housing price distribution
price
count
0.0
500000.0
0.0
500.0
false
false
"set-plot-x-range 0 1000000\nset-plot-y-range 0 1000\nset-histogram-num-bars 11" ""
PENS
"homes" 1.0 1 -16777216 true "" "histogram [cost] of patches with [is-home? = TRUE]"

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

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

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

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

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

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

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
true
0
Line -7500403 true 150 0 150 300

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
false
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
NetLogo 6.1.1
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
1
@#$#@#$#@
