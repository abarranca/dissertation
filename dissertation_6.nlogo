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
  choose-house
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
  [   set is-home? true
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
  ;  if not any? households with [my-home != nobody] [
  ;    stop ] ; if all houses have been bought, stop the simulation
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
        and onMarket? = TRUE
        and my-owner = nobody
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
