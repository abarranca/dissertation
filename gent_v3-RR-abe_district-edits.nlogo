globals [ growth view-mode roads land n-run radial n-resid trial num-districts]
extensions [profiler]

breed [ jobs job ]
breed [ residents a-resident ]
breed [ blockers blocker ]
breed [ assessors assessor ]
breed [ districts district ]

;;;;;;notes - track difference between displacement rate and nature movement rate
;;;;;;check the number of times peopel are displaced - is it one group that is burdened repeatedly?
;;;;;;two DVs - displacement rate and times displaced

patches-own [ quality price sddist prop-min prop-maj prop-trif prop-non-trif closest-trif closest-ntrif
  utility maj-near  local-occupancy block my-hood trifdist ntrifdist trif-pollute
  area-wealth road saturated density my-assessor nw-capital my-wealth gentrifiable gentrified block-gent roaddist
  pdistrict ;; Barranca addition
]
turtles-own [ candidate-patches best-candidate qualifying-patches mover ]
jobs-own [ pollution trif job-block res-block maj-block min-block val maj-prop min-prop ]
residents-own [ race qual wealth newbie my-block similar-nearby home-utility sim-pref class density-pref home-price
  new-price xyz gfiable gfied displaced times-displaced benefit-time move moved home-qual qual-change price-change my-quality-preference my-distance-preference
  my-price-preference my-road-preference
  ideology liberal? age sex-male? collegedegree? professional? hasChild? married? ;; Barranca additions
  annual-income monthly-income consumption monthly-consumption ;; Barranca addition
  owner? renter? ;; Barranca additions
  move-propensity-var ;; Barranca additions
  mydistrict banvote vote-supply-increase-var citywide-supply-vote ;; Barranca additions
  MPC permanent-income ;; Barranca additions from Palley 2008
  ban-neighborhood-baseline vote-supply-increase-baseline
  vote-ban-neighborhood-var vote-ban-neighborhood
  vote-supply-increase-var vote-supply-increase
  ethnicity-white?
  org-influence
  linked?
]
blockers-own [ my-neighbors nimby ]
assessors-own [ assess-block assess-hood hood-res hood-maj hood-min maj-nearby min-nearby residents-in-radius
  trif-nearby non-trif-nearby trif-near ntrif-near saturate block-wealth gent gentf change-rate movers min-movers min-mover-rate mover-wealth wealth-change ]
districts-own [ district-id district-patches district-residents district-opinion ] ;; Barranca addition

to setup
  reset-ticks
  clear-turtles
  clear-patches
  clear-all-plots
  if export-results = true [ sim-runs ]
  set growth 0
  setup-patches
  set num-districts 20 ;; Barranca addition
  grow-districts ;; Barranca addition
  setup-residents
  ;;set view-mode "quality" ;; Barranca removal
  calc-utility
  ask residents [ evaluate ]
  set-district-patches-and-residents ;; Barranca addition
;  ask land [ update-patch-color ] ;; Barranca removal
end

to grow-districts ;; Barranca addition
  Create-districts num-districts
  [
    ;; set district breed shape
    set shape "district"
    __set-line-thickness 1
    set size .2
    ;; Set randomish location...
    setxy random-xcor random-ycor
    ;;; tag this patch
    Set pdistrict self
    ;set district-id district-id + 1
    set color (deep-color-1 who)
    set pcolor color

  ]
  ;; expand districts
  While [ any? Patches with [ pdistrict = 0 ] ]
  [
    Ask patches with
    [ pdistrict != 0  and any? Neighbors with [ pdistrict = 0 ] ]
    [ Ask neighbors with
      [ pdistrict = 0 ]
      [ set pdistrict [ pdistrict] of myself
        Set pcolor [ color ] of pdistrict
      ]
    ]
  ]
end

to set-district-patches-and-residents ;; Barranca addition
  ask districts
  [
    set district-patches patches with [ pdistrict = myself ]
    set district-residents residents with [ mydistrict = myself ]
  ]
end


to reset-runs
  set n-run 0
end

to sim-runs


  set n-run n-run + 1

  if n-run > 5 and n-run <= 10 [
    set nfa? false set density-preference 10 set cleanup-policy "high price" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 1 ]
  if n-run > 10 and n-run <= 15 [
    set nfa? false set density-preference 0 set cleanup-policy "high price" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 2 ]
  if n-run > 15 and n-run <= 20 [
    set nfa? true set density-preference 5 set cleanup-policy "high price" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 3 ]
  if n-run > 20 and n-run <= 25 [
    set nfa? true set density-preference 10 set cleanup-policy "high price" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 4 ]
  if n-run > 25 and n-run <= 30 [
    set nfa? true set density-preference 0 set cleanup-policy "high price" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 5 ]
  if n-run > 30 and n-run <= 35 [
    set nfa? false set density-preference 5 set cleanup-policy "near minority" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 6 ]
  if n-run > 35 and n-run <= 40 [
    set nfa? false set density-preference 10 set cleanup-policy "near minority" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 7 ]
  if n-run > 40 and n-run <= 45 [
    set nfa? false set density-preference 0 set cleanup-policy "near minority" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 8 ]
  if n-run > 45 and n-run <= 50 [
    set nfa? true set density-preference 5 set cleanup-policy "near minority" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 9 ]
  if n-run > 50 and n-run <= 55 [
    set nfa? true set density-preference 10 set cleanup-policy "near minority" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 10 ]
  if n-run > 55 and n-run <= 60 [
    set nfa? true set density-preference 0 set cleanup-policy "near minority" set maj-similarity-preference .8 set min-similarity-preference .5 set trial 11 ]


  if n-run > 60 and n-run <= 65 [
    set nfa? false set density-preference 10 set cleanup-policy "high price" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 12 ]
  if n-run > 65 and n-run <= 70 [
    set nfa? false set density-preference 0 set cleanup-policy "high price" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 13 ]
  if n-run > 70 and n-run <= 75 [
    set nfa? true set density-preference 5 set cleanup-policy "high price" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 14 ]
  if n-run > 75 and n-run <= 80 [
    set nfa? true set density-preference 10 set cleanup-policy "high price" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 15 ]
  if n-run > 80 and n-run <= 85 [
    set nfa? true set density-preference 0 set cleanup-policy "high price" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 16 ]
  if n-run > 85 and n-run <= 90 [
    set nfa? false set density-preference 5 set cleanup-policy "near minority" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 17 ]
  if n-run > 90 and n-run <= 95 [
    set nfa? false set density-preference 10 set cleanup-policy "near minority" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 18 ]
  if n-run > 95 and n-run <= 100 [
    set nfa? false set density-preference 0 set cleanup-policy "near minority" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 19 ]
  if n-run > 100 and n-run <= 105 [
    set nfa? true set density-preference 5 set cleanup-policy "near minority" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 20 ]
  if n-run > 105 and n-run <= 110 [
    set nfa? true set density-preference 10 set cleanup-policy "near minority" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 21 ]
  if n-run > 110 and n-run <= 115 [
    set nfa? true set density-preference 0 set cleanup-policy "near minority" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 22 ]
  if n-run > 115 and n-run <= 120 [
    set nfa? true set density-preference 0 set cleanup-policy "high price" set maj-similarity-preference 0 set min-similarity-preference 0 set trial 23 ]


   if n-run > 120 and n-run <= 125 [
    set nfa? false set density-preference 10 set cleanup-policy "high price" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 24 ]
  if n-run > 125 and n-run <= 130 [
    set nfa? false set density-preference 0 set cleanup-policy "high price" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 25 ]
  if n-run > 130 and n-run <= 135 [
    set nfa? true set density-preference 5 set cleanup-policy "high price" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 26 ]
  if n-run > 135 and n-run <= 140 [
    set nfa? true set density-preference 10 set cleanup-policy "high price" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 27 ]
  if n-run > 140 and n-run <= 145 [
    set nfa? true set density-preference 0 set cleanup-policy "high price" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 28 ]
  if n-run > 145 and n-run <= 150 [
    set nfa? false set density-preference 5 set cleanup-policy "near minority" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 29 ]
  if n-run > 150 and n-run <= 155 [
    set nfa? false set density-preference 10 set cleanup-policy "near minority" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 30 ]
  if n-run > 155 and n-run <= 160 [
    set nfa? false set density-preference 0 set cleanup-policy "near minority" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 31 ]
  if n-run > 160 and n-run <= 165 [
    set nfa? true set density-preference 5 set cleanup-policy "near minority" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 32 ]
  if n-run > 165 and n-run <= 170 [
    set nfa? true set density-preference 10 set cleanup-policy "near minority" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 33 ]
  if n-run > 170 and n-run <= 175 [
    set nfa? true set density-preference 0 set cleanup-policy "near minority" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 34 ]
  if n-run > 175 and n-run <= 180 [
    set nfa? true set density-preference 0 set cleanup-policy "high price" set maj-similarity-preference .3 set min-similarity-preference .3 set trial 35 ]

  if n-run > 180 [ set n-run 1 ]
end

to setup-patches
  ;; PRICES SET ACCORDING TO 2010 CENSUS (IN THOUSANDS OF DOLLARS)
  grow-districts
  ask patches
  [
    set quality 50
    set price ceiling random-gamma 173 43
    ;set density density-preference
  ]

  ;; DIFFUSE PRICE TO MAKE A MORE EVEN PRICED REAL ESTATE MARKET
  repeat 2
  [ diffuse price diffusion-rate ]


  set roads patches with [
    remainder pxcor 10 = 0 or remainder pycor 10 = 0 ]
  ask roads [
    set pcolor white
    set road 1 ]
  set land patches with [ pcolor != white ]

  ask land
  [
    set roaddist min [distance myself + .01] of roads
  ]

  setup-jobs

  ;ask land [ update-patch-color ]
  ask land with [ remainder pxcor 5 = 0 and remainder pycor 5 = 0 ] [
    sprout-blockers 1 ]
  ask blockers [
    set my-neighbors [ who ] of blockers in-radius 14.4
    set color [ pcolor ] of patch-here ]
  ask land [
     let myblock min-one-of blockers [distance myself]
     set block [ who ] of myblock
     set my-hood [ my-neighbors ] of myblock
     set my-hood sort my-hood ]
  ask jobs [
    set job-block [ block ] of patch-here ]
  ask land with [ remainder pxcor 5 = 0 and remainder pycor 5 = 0 ] [
    sprout-assessors 1 [
      set assess-block [ block ] of patch-here
      set assess-hood [ my-hood ] of patch-here
      set color [pcolor] of patch-here ] ]
  ask land [ set my-assessor min-one-of assessors [distance myself] ]
end

to setup-jobs
  create-jobs round ( ( starting-majority + starting-minority ) / residents-per-job )
  ask jobs [
    set shape "house"
    set pollution random 9
    if pollution >= 4 [   ;; 60% disamenities
      set trif 1
      set color orange - 3 ]
    if pollution < 4 [    ;; 40% amenities
      set trif 0
      set color orange ]
    set size 2
    move-to one-of land with [ pycor < 25 and pycor > -25 and pxcor < 25 and pxcor > -25 and not any? residents-here and not any? jobs-here and road != 1 ] ]
end

to setup-residents ;; TODO
  create-residents ( starting-majority + starting-minority )
  ask residents ; Barranca added
  [
    set ideology round random-normal-in-bounds 5 2 1 7 ; 1-7 from extremely conservative to extremely liberal (based on Hankinson 2019)
    set liberal? ifelse-value ( ideology > 4 ) [ 1 ] [ 0 ]
    set age random-poisson-in-bounds 38 18 85
    set sex-male? random one-of [ 0 1 ] ; 1 = male per Hankinson 2019
    ;;set money round random-exponential-in-bounds 50000 0 1000000
    set collegedegree? random 2
    set professional? random 2
    set annual-income round random-exponential-in-bounds 64 12 1000;; Barranca addition
    set monthly-income annual-income / 12
    set MPC random-exponential-in-bounds .5 0 1  ;; Barranca addition based on Palley 2008
    set permanent-income monthly-income  ;; Barranca addition based on Palley 2008
    set consumption MPC * ( permanent-income / mean ( permanent-income ) ) * permanent-income ;; Barranca addition based on Palley 2008
    set monthly-consumption consumption / 12
    set mydistrict [ pdistrict ] of patch-here
    set banvote random-exponential-in-bounds .5 0 1
    set move-propensity-var ( random-float 1 + ( age * .0339 ) + ( age ^ 2 * -.0009 ) + ( hasChild? * -.2564 ) + ( married? * -.1655) + ( owner? * -1.4814 ) + ( renter? * .1180 ) + ( annual-income * 0.00000280) ) ; propensity weights based on odds ratios from Clark 2013
  ]
  ask n-of starting-majority residents [
    set color red + 2
    set shape "circle"
    set race 1 ;; majority
    ifelse race = 0 [ set ethnicity-white? 1 ] [ set ethnicity-white? 0 ]
    set mover 1
    set size 1
    set newbie 1
    set wealth ceiling random-gamma majority-wealth majority-wealth-stdev
    set my-quality-preference random-normal quality-preference .1
    set my-price-preference random-normal price-preference .1
    set my-distance-preference random-normal distance-preference .1
    set my-road-preference random-normal .5 .1
    ifelse density-preference = 0
    [ set density-pref 1 ]
    [ set density-pref random-normal density-preference 1 ]
    if density-pref < 1 [ set density-pref 0 ]
    class-set
    set my-block [ block ] of patch-here
    set liberal? one-of [ 0 1 ]
    set age random-poisson-in-bounds 32 18 75
    set ban-neighborhood-baseline random-float 1
    set vote-ban-neighborhood-var ( ban-neighborhood-baseline + ( .08 * owner? ) + ( -.03 * liberal? ) + ( ln annual-income * -.01 ) + ( ethnicity-white? * -.05 ) + ( age * -.0004 ) + ( sex-male? * -.02 ) + (org-influence * linked?)) ; from Hankinson 2019 Table B.4. Sex 1 = Male. Added input of org-influence.
    set vote-ban-neighborhood vote-ban-neighborhood-var / ( 1 + vote-ban-neighborhood-var )
    set vote-supply-increase-baseline random-float 1
    set vote-supply-increase-var ( vote-supply-increase-baseline + ( -.25 * owner? ) + ( .04 * liberal? ) + ( ln annual-income * -.02 ) + ( ethnicity-white? * -.09 ) + ( age * -.001 ) + ( sex-male? * .06 ) + (org-influence * linked?))
    set vote-supply-increase vote-supply-increase-var / ( 1 + vote-supply-increase-var )
  ]

  ask n-of starting-minority residents with [ race != 1 ] [
    set color yellow + 2
    set shape "circle"
    set race 2 ;; minority
    set mover 1
    set size 1
    set newbie 1
    set wealth ceiling random-gamma minority-wealth minority-wealth-stdev
    set my-quality-preference random-normal quality-preference .1
    set my-price-preference random-normal price-preference .1
    set my-distance-preference random-normal distance-preference .1
    set my-road-preference random-normal .5 .1
    ifelse density-preference = 0
    [ set density-pref 1 ]
    [ set density-pref random-normal density-preference 1 ]
    if density-pref < 1 [ set density-pref 0 ]
    class-set
    set my-block [ block ] of patch-here
    set ban-neighborhood-baseline random-float 1
    set vote-ban-neighborhood-var ( ban-neighborhood-baseline + ( .08 * owner? ) + ( -.03 * liberal? ) + ( ln permanent-income * -.01 ) + ( ethnicity-white? * -.05 ) + ( age * -.0004 ) + ( sex-male? * -.02 ) + (org-influence * linked?)) ; from Hankinson 2019 Table B.4. Sex 1 = Male. Added input of org-influence.
    set vote-ban-neighborhood vote-ban-neighborhood-var / ( 1 + vote-ban-neighborhood-var )
    set vote-supply-increase-baseline random-float 1
    set vote-supply-increase-var ( vote-supply-increase-baseline + ( -.25 * owner? ) + ( .04 * liberal? ) + ( ln permanent-income * -.02 ) + ( ethnicity-white? * -.09 ) + ( age * -.001 ) + ( sex-male? * .06 ) + (org-influence * linked?))
    set vote-supply-increase vote-supply-increase-var / ( 1 + vote-supply-increase-var )

  ]
end

to class-set
  ;; defining classes according to poverty at 150% of the poverty rate for a family of 3, and rich at the 2nd highest federal tax bracket.
  if wealth < 0 [ set wealth ceiling random 28 ]
  ifelse wealth < 28
    [ set class 1 ]  ;; poor
    [
      ifelse wealth > 100
      [ set class 3 ]  ;; rich
      [ set class 2 ]  ;; middle
    ]
end

to move-around
  let moving-majority ( count residents with [ race = 1 ] * majority-probability-of-moving )
  ask n-of moving-majority residents [ set mover 1 ]
  let moving-minority ( count residents with [ race = 2 ] * minority-probability-of-moving )
  ask n-of moving-minority residents [ set mover 1 ]
  ask residents [ if mover = 1 [ evaluate ] ]
end

to assess
  ;; UPDATE NEIGHBORHOOD COMPOSITION AT EACH TICK
  ask assessors [
    if ( count patches in-radius 10 with [ gentrified = 1 ] / count patches in-radius 10 ) > .5 [ set gent 1 ]
    if ( count patches in-radius 10 with [ gentrifiable = 1 ] / count patches in-radius 10 ) > .5 [ set gentf 1 ]
    set residents-in-radius residents in-radius 10
    set hood-res count ( residents-in-radius )
    set hood-maj count ( residents-in-radius with [ race = 1 ] )
    set hood-min count ( residents-in-radius with [ race = 2 ] )
    ifelse hood-res > 0
    [ set block-wealth mean [ wealth ] of residents-in-radius ]
    [ set block-wealth .01 ]
  ]

  ask assessors [
    ifelse hood-res = 0
    [
      set maj-nearby 0
      set min-nearby 0
    ]
    [
      set maj-nearby hood-maj / hood-res
      set min-nearby hood-min / hood-res
      let move-group residents-in-radius with [ moved = 1 ]
      set movers count move-group
      if movers != 0
      [
      set change-rate movers / hood-res
      set min-movers count move-group with [ race = 2 ]
      set min-mover-rate min-movers / movers
      set mover-wealth mean [ wealth ] of move-group
      set wealth-change mover-wealth - block-wealth
      ]
    ]
  ]
end

to calc-utility
  ;; SET UP PATCHES TO BE SELECTED BY RESIDENTS TO RELOCATE - USE ASSESSORS TO DETERMINE NEIGHBORHOOD COMPOSITION AND CALCULATE DISTANCE TO AMEN/DISAMEN

    assess
    ask land [
      set prop-maj [ maj-nearby ] of my-assessor
      set prop-min [ min-nearby ] of my-assessor
      set block-gent [ gent ] of my-assessor
      set density count residents-here
      set my-wealth [ block-wealth ] of my-assessor
      set closest-trif min-one-of jobs with [ trif = 1 ] [ distance myself ]
      set closest-ntrif min-one-of jobs with [ trif = 0 ] [ distance myself ]
      ifelse closest-trif != nobody
        [ set trifdist [ distance myself + .01 ] of closest-trif
          set trif-pollute [ pollution ] of closest-trif ]
        [ set trifdist max [ pxcor ] of patches
          set trif-pollute 0 ]
      ifelse closest-ntrif != nobody
        [ set ntrifdist [ distance myself + .01 ] of closest-ntrif ]
        [ set ntrifdist max [ pxcor ] of patches ]

      ;; ADJUST PRICES AND QUALITY LEVELS
      if my-wealth > 28  [ set price ( price + ( ( 2 * my-wealth ) - price ) ) ]

      if any? residents-here [ set quality ( quality + ( quality * .01 ) ) ]
      set quality ( quality * ( 1 - ( 1 / trifdist ^ quality-exp-decay-rate ) ) )
      set quality ( quality * ( 1 + ( 1 / ntrifdist ^ quality-exp-decay-rate) ) )

      if quality > 100 [ set quality 100 ]
      if quality < 1 or quality = "NaN" [ set quality 1 ]
      ;; don't let prices go negative -- if they get too low, they are set at a random number at twice our poverty rate indicator.
      if price < 1 or price = "NaN" [ set price ceiling random 56 ]

      ;; declare the patch to be gentrfiable - basically if it is roughly the bottom quartile of price, and if race is a factor, if minorities live there
      let quart2 mean [ price ] of land
      let sdland standard-deviation [ price ] of land
      let quart1 quart2 - ( 1.5 * sdland )
      ifelse race-in-gent = "On"
      [ if price < quart1 and any? residents-here with [ race = 2 ] [ set gentrifiable 1  ] ]
      [ if price < quart1 [ set gentrifiable 1 ] ]

      ;; declare the patch to be gentrified
      ifelse race-in-gent = "On"
      [ if gentrifiable = 1 and price > ( mean [ price ] of land ) and any? residents-here with [ race = 1 ] [ set gentrified 1 set gentrifiable 0 ] ]
      [ if gentrifiable = 1 and price > ( mean [ price ] of land ) [ set gentrified 1 set gentrifiable 0 ] ]
 ]
end

to go
  ;; CLEANUP BEGINS AFTER TICK 25
  if ticks > 25 [ cleanup ]

  set n-resid count residents
  locate-residents
  if count (residents) / count (jobs) > residents-per-job [ locate-service ]
  if count (residents) >= 500 [kill-residents]

  ;; RESIDENTS DON'T MOVE IN FIRST 25 TICKS EITHER - SET UP A RACIALLY SEGREGATED WORLD
  if ticks > 25 [ move-around ]

  move-around
  calc-utility
  job-effect
;  update-view
  do-plots
  ask blockers [ set color [ pcolor ] of patch-here ]
  ask assessors [ set color [ pcolor ] of patch-here ]

  if export-results = true [ export-data ]
  ask residents [ set moved 0 ]
  tick
end

to locate-residents
  set growth count (residents) * growth-rate * 1.20
  set growth ceiling (growth)
  ask n-of growth residents [
    hatch 1 [
      set newbie 1
      set mover 1
      ifelse race = 1
        [ set wealth random-gamma majority-wealth majority-wealth-stdev ]
        [ set wealth random-gamma minority-wealth minority-wealth-stdev ]
      set my-quality-preference random-normal quality-preference .1
      set my-price-preference random-normal price-preference .1
      set my-distance-preference random-normal distance-preference .1
      set my-road-preference random-normal .5 .1
      class-set
          ifelse density-preference = 0
          [ set density-pref 1 ]
          [ set density-pref random-normal density-preference 1 ]
          if density-pref < 1 [ set density-pref 0 ]
      evaluate ] ]
end

to evaluate
  ;; RESIDENTS AT THE START SELECT A LOCATION THAT MEETS THEIR PREFERENCES, OTHERWISE IF RESIDENTS MOVE, RETAIN HOME QUALITY AND HOME PRICE INFORMATION
  ;; ALSO ASSESSES WHETHER THEIR HOME PATCH IS EITHER GENTRIFIABLE OR GENTRIFIED

  ifelse newbie = 1
  [ set home-utility [ utility ] of patch-here
    set home-price [ price ] of patch-here
    set home-qual [ quality ] of patch-here
    set new-price 1 ]
  [
    set home-utility [ utility ] of patch-here
    set home-price [ price ] of patch-here
    set home-qual [ quality ] of patch-here
    if [ gentrifiable ] of patch-here = 1 [ set gfiable 1 ]
    if [ block-gent ] of patch-here  = 1 [ set gfied 1 ]
  ]

  ;; SET WILLINGNESS TO PAY AT NO MORE THAN 3X WEALTH AND NO LOWER THAN WEALTH
  let wtp-max 3 * wealth
  let wtp-min wealth
  set candidate-patches land with [ not any? jobs-here and road != 1 and price < wtp-max and price > wtp-min ]
  set owner? 1
  set renter? 0
  ;; IF NO PATCHES IN THEIR WEALTH RANGE, LOOK FIRST FOR ANYTHING CHEAPER AND THEN FINALLY FOR ANY OPEN SPOTS (LATTER IS RARE - ONLY IF WORLD IS FULL)
  if not any? candidate-patches [
    set candidate-patches land with [  not any? jobs-here and road != 1 and price < wtp-max ]
  ]
  set owner? 0
  set renter? 1
  if not any? candidate-patches [
    set candidate-patches land with [   not any? jobs-here and road != 1 ]
  ]
  set owner? 0
  set renter? 1
  ;; MAJORITY SELECTION PROCESS
  ;; SLIGHTLY DIFFERENT PROCESSES IF DENSITY PREFERENCE IS 0 OR > 0
  ;; IF 0, SELECT ONLY PLOTS WITH NO OTHER RESIDENTS. IF ABOVE ZERO, DO NOT EXCEED DENSITY PREFERENCE
  ;; AND NARROW POSSIBLE CHOICES TO THOSE MATCHING SIMILARITY PREFERENCE
  ;; THEN CALCULATE THE UTILITY FOR PATCHES WITHIN SELECTED POSSIBILITIES
  ;; NEW MECHANISM - RANDOMLY CHOOSE WHETHER THEY ARE SELECTING THE BEST PLOT BASED ON UTILITY FUNCTION
     ;; OR BASED ON MAKING THE MOST PERSONAL PROFIT OFF OF THE SELECTION CHOICE
     ;; EFFECTIVELY, HALF OF THE MOVERS WILL CHOOSE A LOCATION TO INCREASE THEIR UTILITY WHILE HALF CHOOSE TO MAXIMIZE THEIR REAL ESTATE PROFIT
     ;; THIS WAS DONE TO ENSURE THAT THERE WERE "PROSPECTORS" WHO WOULD TRY TO TAKE ADVANTAGE OF LOW PRICES IN GENTRIFIABLE AREAS (SMITH'S RENT GAP THESIS)
  ;; PROCESS FOR MINORITY AGENTS IS THE SAME

  if race = 1 [
    ifelse newbie = 1
    [ set qualifying-patches land  with [ prop-min < ( 1 - maj-similarity-preference ) and not any? residents-here ] ]
    [ set qualifying-patches candidate-patches with [ prop-min < ( 1 - maj-similarity-preference ) ] ]

    ;ifelse density-preference = 0
    ;[
    ;  if (not any? qualifying-patches) [ set xyz 1 set qualifying-patches candidate-patches with [ not any? residents-here ] ]
    ;  if (not any? qualifying-patches) [ stop ]
    ;]
    ;[
    ;  if (not any? qualifying-patches) [ set xyz 1 set qualifying-patches candidate-patches with [ density <= [ density-pref ] of myself ] ]
      if (not any? qualifying-patches) [ set xyz 2 set qualifying-patches land with [ not any? jobs-here ] ]
    ;]

    ifelse density-preference = 0
      [ ask qualifying-patches [ set utility ( quality ^ quality-preference ) * ( ( 1 / price ) ^ price-preference ) * ( ( 1 / ( sddist + .01 ) ) ^ ( distance-preference ) ) * ( ( 1 / (roaddist + .01) ) ^ .5 ) ] ]
      [ ask qualifying-patches [ set utility ( quality ^ quality-preference ) * ( ( 1 / price ) ^ price-preference ) * ( 1 / ( density + .01 ) ^ .5 ) * ( ( 1 / ( sddist + .01 ) ) ^ ( distance-preference ) ) * ( ( 1 / (roaddist + .01) ) ^ .5 ) ] ]

    let choice random 1
    ifelse choice = 0
      [ set best-candidate max-one-of qualifying-patches [ utility ] ]
      [ set best-candidate min-one-of qualifying-patches [ price ]
        set new-price [ price ] of best-candidate
        set wealth wealth + ( home-price - new-price ) ]

    ;if [ density ] of best-candidate < ( density-preference ) [
      let rent [ price ] of best-candidate / 240
      let income wealth / 12
      let housing_burden rent / ( income + .01 )
      if [ utility ] of best-candidate > home-utility or housing_burden >= random-normal .5 .1 [ move-to best-candidate set move 1 set moved 1 ]

    ;]
  ]

  if race = 2 [
    ifelse newbie = 1
    [ set qualifying-patches land with [ prop-maj < ( 1 - min-similarity-preference ) and not any? residents-here ] ]
    [ set qualifying-patches candidate-patches with [ prop-maj < ( 1 - min-similarity-preference ) ] ]
   ifelse ticks < 25
     [ set best-candidate min-one-of qualifying-patches with [ road != 1 ] [ quality ]
       if best-candidate != nobody [ move-to best-candidate ] ]
     [
    ;ifelse density-preference = 0
    ;[
    ;  if (not any? qualifying-patches) [ set xyz 1 set qualifying-patches candidate-patches with [ not any? residents-here ] ]
    ;  if (not any? qualifying-patches) [ stop ]
    ;]
    ;[
    ;  if (not any? qualifying-patches) [ set xyz 1 set qualifying-patches candidate-patches with [ density <= [ density-pref ] of myself ] ]
      if (not any? qualifying-patches) [ set xyz 2 set qualifying-patches land with [ not any? jobs-here ] ]
    ;]


    ifelse density-preference = 0
      [ ask qualifying-patches [ set utility ( quality ^ quality-preference ) * ( ( 1 / price ) ^ price-preference ) * ( ( 1 / ( sddist + .01 ) ) ^ ( distance-preference ) ) * ( ( 1 / (roaddist + .01) ) ^ .5 ) ] ]
      [ ask qualifying-patches [ set utility ( quality ^ quality-preference ) * ( ( 1 / price ) ^ price-preference ) * ( 1 / ( density + .01 ) ^ .5 ) * ( ( 1 / ( sddist + .01 ) ) ^ ( distance-preference ) ) * ( ( 1 / (roaddist + .01) ) ^ .5 ) ] ]

    let choice random 1
    ifelse choice = 0
    [ set best-candidate max-one-of qualifying-patches [ utility ] ]
    [ set best-candidate min-one-of qualifying-patches [ price ]
      set new-price [ price ] of best-candidate
      set wealth wealth + ( home-price - new-price ) ]

    ;if [ density ] of best-candidate < ( density-preference ) [
      let rent [ price ] of best-candidate / 240
      let income wealth / 12
      let housing_burden rent / ( income + .01 )
      if [ utility ] of best-candidate > home-utility or housing_burden >= random-normal .5 .1 [ move-to best-candidate set move 1 set moved 1 ]

    ;]
  ]
     ]
if move = 1
  [
     if newbie = 0 and gfiable = 1 and gfied = 1 and [ gentrified ] of patch-here = 0 [ set displaced 1 ]
     if newbie = 0 and gfied = 0 and [ gentrified ] of patch-here = 0 [ set displaced 0 ]
     set times-displaced times-displaced + displaced
     set qual-change [ quality ] of patch-here - home-qual
     set price-change [ price ] of patch-here - home-price
  ]
if move = 0
[
  if newbie = 0 and gfiable = 1 and gfied = 1 [ set benefit-time benefit-time + 1 ]
]

  set mover 0
  set move 0
  set newbie 0
  set my-block [ block ] of patch-here
  set mydistrict [ pcolor ] of patch-here ; Barranca addition
end

to kill-residents
  set growth count (residents) * growth-rate * .20
  repeat floor (growth) [
    ask min-one-of residents [ who ] [ die ] ]
end


to locate-service
  let empty-patches land with [ not any? residents-here and not any? jobs-here ]
  if any? empty-patches [
    ask one-of empty-patches [
      sprout-jobs 1 [
        set shape "house"
        set pollution random 10
        if pollution >= 5 [
          set trif 1
          set color orange - 3]
        if pollution < 5 [
          set trif 0
          set color orange ]
        set size 2
        set mover 1
        evaluate-trif ] ] ]
end

to evaluate-trif
  if trif = 0 [
    set candidate-patches land with [ not any? jobs-here and not any? residents-here and saturated < 5 ]
    if not any? candidate-patches [ set candidate-patches land with [ not any? jobs-here and not any? residents-here ] ]

    ifelse ntrifs-choose = "low price"
    [ set best-candidate min-one-of candidate-patches [ price ] ]
    [ set best-candidate max-one-of candidate-patches [ prop-maj ] ]
    move-to best-candidate
  ]

  if trif = 1 [
    set candidate-patches land with [ not any? jobs-here and not any? residents-here and saturated < 5 ]
    if not any? candidate-patches [ set candidate-patches land with [ not any? jobs-here and not any? residents-here  ] ]

    if trifs-choose = "near minority" [
      set best-candidate max-one-of candidate-patches [ prop-min ] ]
    if trifs-choose = "away from majority" [
      set best-candidate min-one-of candidate-patches with [ prop-maj > 0 ] [ prop-maj ] ]
      if best-candidate = nobody [ set best-candidate min-one-of candidate-patches [ prop-maj ] ]
    if trifs-choose = "low price" [
      set best-candidate min-one-of candidate-patches [ price ] ]
    move-to best-candidate
    ]

  if trif = 1 [ decrease-value ]
  if trif = 0 [ raise-value ]
  set mover 0
  set job-block [ block ] of patch-here
end

to decrease-value
  let decrease-rate ( .01 * ( 100 - pollution ) )
  let neighbor-decrease-rate ( .01 * ( 100 - ( pollution / 2 ) ) )
  ask land with [ block  = [ block ] of myself ]  [ set quality ( quality * neighbor-decrease-rate ) ]
  ask patch-here [ set quality ( quality * decrease-rate ) ]
end

to raise-value
  let increase-rate ( 1 + (.01 * ( 5 - pollution ) ) )
  let neighbor-increase-rate ( 1 + ( .01 * ( 5 - ( pollution / 2 ) ) ) )
  ask land with [ block  = [ block ] of myself ]  [ set quality ( quality * neighbor-increase-rate ) ]
  ask patch-here [ set quality ( quality * increase-rate ) ]
end

to cleanup
  ;; CLEANUP UP ONE DISAMENITY PER TICK AFTER TICK 25
  ;; IF THE NFA CHOOSER IS TOGGLED ON, TURN THE DISAMENITY INTO AN AMENITY
  ;; IF THE NFA CHOOSER IS TOGGLED OFF, JUST DELET THE DISAMENITY
  ;; CLEANUP UP ACCORDING TO WHATEVER PRIORITY IS CHOSEN ON THE SELECTION BOX ON THE INTERFACE

  if any? jobs with [ trif = 1 ] [
    ask jobs [
      set val [ price ] of patch-here
      set min-prop [ prop-min ] of patch-here
      set maj-prop [ prop-maj ] of patch-here
    ]

  if cleanup-policy = "high price"[
    ifelse nfa?
    [ ask max-one-of jobs with [ trif = 1 ] [ val ]
      [ die ]]
    [ ask max-one-of jobs with [ trif = 1 ] [ val ]
      [ set pollution 0
        set trif 0
        set color 117 ]
    ]]

  if cleanup-policy = "high pollution" [
    ifelse nfa?
    [ ask max-one-of jobs with [ trif = 1 ] [ pollution ]
      [ die ] ]
    [ ask max-one-of jobs with [ trif = 1 ] [ pollution ]
      [ set pollution 0
        set trif 0
        set color 117 ]
    ]]

  if cleanup-policy = "near majority" [
    ifelse nfa?
    [ ask max-one-of jobs with [ trif = 1 ] [ maj-prop ]
      [ die ] ]
    [ ask max-one-of jobs with [ trif = 1 ] [ maj-prop ]
      [ set pollution 0
        set trif 0
        set color 117 ]
    ]]

  if cleanup-policy = "near minority"[
    ifelse nfa?
    [ ask max-one-of jobs with [ trif = 1 ] [ min-prop ]
      [ die ] ]
    [ ask max-one-of jobs with [ trif = 1 ] [ min-prop ]
      [ set pollution 0
        set trif 0
        set color 117 ]
    ]]
  ]

  ;; RECALCULATE ALL DISTANCES AFTER THE DISAMENITY IS REMOVED/CHANGED
  ask patches
    [ set sddist min [distance myself + .01] of jobs
      ifelse any? jobs with [ trif = 1 ]
      [
        set trifdist min [distance myself + .01] of jobs with [ trif = 1 ]
        set trif-pollute [ pollution ] of min-one-of jobs with [ trif = 1 ] [ distance myself ]
      ]
      [
        set trifdist 100
        set trif-pollute 1
      ]
      set ntrifdist min [distance myself + .01] of jobs with [ trif = 0 ]
      ]
end

to job-effect
  diffuse quality diffusion-rate
  diffuse price diffusion-rate
  ask roads [
    set quality 50
    ]
end

;to update-view
;  ask land [ update-patch-color ]
;end

;to update-patch-color
;  if view-mode = "quality" [
;    set pcolor scale-color green quality 0 100 ]
;  if view-mode = "price" [
;    let minp ceiling min [ price ] of land
;    let maxp ceiling max [ price ] of land
;    set pcolor scale-color cyan price minp maxp ]
;end

to do-plots
  set-current-plot "Race"
  set-current-plot-pen "MA"
  plot mean [ quality ] of patches with [ any? residents-here with [ race = 1 ] ]
  set-current-plot-pen "MI"
  plot mean [ quality ] of patches with [ any? residents-here with [ race = 2 ] ]


  ;set-current-plot "Wealth"
  ;set-current-plot-pen "poor"
  ;plot mean [ quality ] of patches with [ any? residents-here with [ class = 1 ] ]
  ;set-current-plot-pen "middle"
  ;plot mean [ quality ] of patches with [ any? residents-here with [ class = 2 ] ]
  ;if any? residents with [ class = 3 ]
  ;[
  ;set-current-plot-pen "rich"
  ;plot mean [ quality ] of patches with [ any? residents-here with [ class = 3 ] ]
  ;]

  set-current-plot "Quality Detail"
  if any? residents with [ race = 1 and class = 3 ]
  [
  set-current-plot-pen "richmaj"
  plot mean [ quality ] of patches with [ any? residents-here with [ race = 1 and class = 3 ] ]
  ]
  if any? residents with [ race = 1 and class = 2 ]
  [
  set-current-plot-pen "midmaj"
  plot mean [ quality ] of patches with [ any? residents-here with [ race = 1 and class = 2 ] ]
  ]
  if any? residents with [ race = 1 and class = 1 ]
  [
  set-current-plot-pen "poormaj"
  plot mean [ quality ] of patches with [ any? residents-here with [ race = 1 and class = 1 ] ]
  ]
  if any? residents with [ race = 2 and class = 3 ]
  [
  set-current-plot-pen "richmin"
  plot mean [ quality ] of patches with [ any? residents-here with [ race = 2 and class = 3 ] ]
  ]
  if any? residents with [ race = 2 and class = 2 ]
  [
  set-current-plot-pen "midmin"
  plot mean [ quality ] of patches with [ any? residents-here with [ race = 2 and class = 2 ] ]
  ]
  if any? residents with [ race = 2 and class = 1 ]
  [
  set-current-plot-pen "poormin"
  plot mean [ quality ] of patches with [ any? residents-here with [ race = 2 and class = 1 ] ]
  ]
end


to export-data
  file-open "gent_model.csv"
  if n-run = 1 and ticks = 0 [ file-print " " ]
    file-type ticks
    file-type ","
    file-type n-run
    file-type ","
    file-type trial
    file-type ","
    file-type mean [ quality ] of land with [ any? residents-here with [ race = 1 ] ]
    file-type ","
    file-type mean [ price ] of land with [ any? residents-here with [ race = 1 ] ]
    file-type ","
    file-type count residents with [ race = 1 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ race = 1 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ race = 1 ]
    file-type ","
    file-type count residents with [ race = 1 ]
    file-type ","
    file-type mean [ quality ] of land with [ any? residents-here with [ race = 2 ] ]
    file-type ","
    file-type mean [ price ] of land with [ any? residents-here with [ race = 2 ] ]
    file-type ","
    file-type count residents with [ race = 2 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ race = 2 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ race = 2 ]
    file-type ","
    file-type count residents with [ race = 2 ]
    file-type ","
    file-type mean [ quality ] of land with [ any? residents-here with [ class = 1 ] ]
    file-type ","
    file-type mean [ price ] of land with [ any? residents-here with [ class = 1 ] ]
    file-type ","
    file-type count residents with [ class = 1 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ class = 1 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ class = 1 ]
    file-type ","
    file-type count residents with [ class = 1 ]
    file-type ","
    file-type mean [ quality ] of land with [ any? residents-here with [ class = 2 ] ]
    file-type ","
    file-type mean [ price ] of land with [ any? residents-here with [ class = 2 ] ]
    file-type ","
    file-type count residents with [ class = 2 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ class = 2 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ class = 2 ]
    file-type ","
    file-type count residents with [ class = 2 ]
    file-type ","

    ifelse any? residents with [ class = 3 ]
    [
      file-type mean [ quality ] of land with [ any? residents-here with [ class = 3 ] ]
      file-type ","
      file-type mean [ price ] of land with [ any? residents-here with [ class = 3 ] ]
      file-type ","
      file-type count residents with [ class = 3 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ class = 3 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ class = 3 ]
    file-type ","
      file-type count residents with [ class = 3 ]
      file-type ","
    ]
    [
      file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
            file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
    ]

    ifelse any? residents with [ race = 1 and class = 1 ]
    [
      file-type mean [ quality ] of land with [ any? residents-here with [ race = 1 and class = 1 ] ]
      file-type ","
      file-type mean [ price ] of land with [ any? residents-here with [ race = 1 and class = 1 ] ]
      file-type ","
       file-type count residents with [ race = 1 and class = 1 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ race = 1 and class = 1 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ race = 1 and class = 1 ]
    file-type ","
      file-type count residents with [ race = 1 and class = 1 ]
      file-type ","
    ]
    [
      file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
            file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
    ]

    ifelse any? residents with [ race = 1 and class = 2 ]
    [
      file-type mean [ quality ] of land with [ any? residents-here with [ race = 1 and class = 2 ] ]
      file-type ","
      file-type mean [ price ] of land with [ any? residents-here with [ race = 1 and class = 2 ] ]
      file-type ","
             file-type count residents with [ race = 1 and class = 2 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ race = 1 and class = 2 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ race = 1 and class = 2 ]
    file-type ","
       file-type count residents with [ race = 1 and class = 2 ]
       file-type ","
    ]
    [
      file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
            file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
    ]

    ifelse any? residents with [ race = 1 and class = 3 ]
    [
      file-type mean [ quality ] of land with [ any? residents-here with [ race = 1 and class = 3 ] ]
      file-type ","
      file-type mean [ price ] of land with [ any? residents-here with [ race = 1 and class = 3 ] ]
      file-type ","
             file-type count residents with [ race = 1 and class = 3 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ race = 1 and class = 3 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ race = 1 and class = 3 ]
    file-type ","
      file-type count residents with [ race = 1 and class = 3 ]
      file-type ","
    ]
    [
      file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
            file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
    ]

    ifelse any? residents with [ race = 2 and class = 1 ]
    [
      file-type mean [ quality ] of land with [ any? residents-here with [ race = 2 and class = 1 ] ]
      file-type ","
      file-type mean [ price ] of land with [ any? residents-here with [ race = 2 and class = 1 ] ]
      file-type ","
             file-type count residents with [ race = 2 and class = 1 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ race = 2 and class = 1 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ race = 2 and class = 1 ]
    file-type ","
      file-type count residents with [ race = 2 and class = 1 ]
      file-type ","
    ]
    [
      file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
            file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
    ]

    ifelse any? residents with [ race = 2 and class = 2]
    [
      file-type mean [ quality ] of land with [ any? residents-here with [ race = 2 and class = 2 ] ]
      file-type ","
      file-type mean [ price ] of land with [ any? residents-here with [ race = 2 and class = 2 ] ]
      file-type ","
             file-type count residents with [ race = 2 and class = 2 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ race = 2 and class = 2 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ race = 2 and class = 2 ]
    file-type ","
      file-type count residents with [ race = 2 and class = 2 ]
      file-type ","
    ]
    [
      file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
            file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
    ]

    ifelse any? residents with [ race = 2 and class = 3 ]
      [
        file-type mean [ quality ] of land with [ any? residents-here with [ race = 2 and class = 3 ] ]
        file-type ","
        file-type mean [ price ] of land with [ any? residents-here with [ race = 2 and class = 3 ] ]
        file-type ","
               file-type count residents with [ race = 2 and class = 3 and gfied = 1 ]
    file-type ","
    file-type mean [ times-displaced ] of residents with [ race = 2 and class = 3 ]
    file-type ","
    file-type mean [ benefit-time ] of residents with [ race = 2 and class = 3 ]
    file-type ","
        file-type count residents with [ race = 2 and class = 3 ]
        file-type ","
      ]
      [
        file-type 0
        file-type ","
        file-type 0
        file-type ","
        file-type 0
        file-type ","
              file-type 0
      file-type ","
      file-type 0
      file-type ","
      file-type 0
      file-type ","
      ]

    file-type cleanup-policy
    file-type ","
    file-type nfa?
    file-type ","
    file-type count land with [ gentrified = 1 ]
    file-type ","
    file-type count land with [ gentrifiable = 1 ]
    file-type ","
    file-type count assessors with [ gent = 1 ] / count assessors
    file-type ","
    file-type count assessors with  [ gentf = 1 ] / count assessors
    file-type ","
    file-type count residents with [ gfied  = 1 ]  / count residents
    file-type ","
    file-type  count residents with [ gfied = 1 and race = 2 ] / count residents with [ race = 2 ]
    file-type ","
    file-type count residents with [ displaced = 1 ] / count residents
    file-type ","
    file-type count residents with [ displaced = 1 and race = 2 ] / count residents with [ race = 2 ]
    file-type ","

    file-type mean [ movers ] of assessors
    file-type ","
    file-type mean [ wealth-change ] of assessors
    file-type ","
    file-type mean [ change-rate ] of assessors
    file-type ","
    carefully [ file-type mean [ movers ] of assessors with [ gent = 1 ] ] [ file-type 0 ]
    file-type ","
    carefully [ file-type mean [ wealth-change ] of assessors with [ gent = 1 ] ] [ file-type 0 ]
    file-type ","
    carefully [ file-type mean [ change-rate ] of assessors with [ gent = 1 ] ] [ file-type 0 ]
    file-type ","

    file-type mean [ quality ] of land with [ any? residents-here ]
    file-type ","
    file-type mean [ quality ] of land
    file-type ","
    file-type count jobs with [ trif = 1 ]
    file-type ","
    file-type count jobs
    file-type ","
    file-type majority-probability-of-moving
    file-type ","
    file-type minority-probability-of-moving
    file-type ","
    file-type density-preference
    file-type ","
    file-type precision min-similarity-preference 1
    file-type ","
    file-print precision maj-similarity-preference 1
    file-close

  if ticks = 75 [ setup ]
end

to-report random-normal-in-bounds [mid dev mmin mmax]
  let result random-normal mid dev
  if result < mmin or result > mmax
    [ report random-normal-in-bounds mid dev mmin mmax ]
  report result
end

to-report random-exponential-in-bounds [mid mmin mmax]
  let result random-exponential mid
  if result < mmin or result > mmax
    [ report random-exponential-in-bounds mid mmin mmax ]
  report result
end

to-report random-poisson-in-bounds [lambda mmin mmax]
  let result random-poisson lambda
  if result < mmin or result > mmax
    [ report random-poisson-in-bounds lambda mmin mmax ]
  report result
end


to-report district-opinion-reporter-ban
  ;let district-residents count residents with [mydistrict = [pdistrict] of myself ]
  let this-opinion ifelse-value count residents with [ mydistrict = [pdistrict] of myself] = 0 [0] [(count residents with [vote-ban-neighborhood > .5 and mydistrict = [pdistrict] of myself]) / count residents with [ mydistrict = [pdistrict] of myself] ]
  report this-opinion
end

to-report district-opinion-reporter-supply-increase
  ;let district-residents count residents with [mydistrict = [pdistrict] of myself ]
  let this-opinion ifelse-value count residents with [ mydistrict = [pdistrict] of myself] = 0 [0] [(count residents with [vote-supply-increase > .5 and mydistrict = [pdistrict] of myself]) / count residents with [ mydistrict = [pdistrict] of myself] ]
  report this-opinion
end

to-report cityopinion
  let districts-aggregate (count districts with [ district-opinion > .5 ] ) / count districts
  report districts-aggregate
end

to-report deep-color-1 [ value ]
  report (
  red + 10 * (value mod 13) ;; base netlogo color
  ;; shift up or down
  +  .5 * ( (int (value / 13 )) mod 2 * 2 - 1) ;; alternate normal -1, +1
  ;; increase difference (gets brighter and darker)
  * (1 + int ( value / ( 2 * 13 )))
  )
end

;to-report
;
;end

;to-report district1-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 5])/(count turtles with [mydistrict = 5]) > .5 [1] [0]
;end
;
;to-report district2-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 15])/(count turtles with [mydistrict = 15]) > .5 [1] [0]
;end
;
;to-report district3-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 25])/(count turtles with [mydistrict = 25]) > .5 [1] [0]
;end
;
;to-report district4-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 35])/(count turtles with [mydistrict = 35]) > .5 [1] [0]
;end
;
;to-report district5-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 45])/(count turtles with [mydistrict = 45]) > .5 [1] [0]
;end

;to-report district6-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 55])/(count turtles with [mydistrict = 55]) > .5 [1] [0]
;end
;
;to-report district7-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 65])/(count turtles with [mydistrict = 65]) > .5 [1] [0]
;end
;
;to-report district8-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 75])/(count turtles with [mydistrict = 75]) > .5 [1] [0]
;end
;
;to-report district9-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 85])/(count turtles with [mydistrict = 85]) > .5 [1] [0]
;end
;
;to-report district10-vote [ param ]
;  report if-else (count residents with [opinion > .5 and mydistrict = 95])/(count turtles with [mydistrict = 95]) > .5 [1] [0]
;end
@#$#@#$#@
GRAPHICS-WINDOW
282
8
671
398
-1
-1
9.3
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
5
8
90
42
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

BUTTON
95
8
177
42
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

BUTTON
181
8
277
42
go-once
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
44
90
78
view price
set view-mode \"price\"\nupdate-view
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
95
44
177
78
view quality
set view-mode \"quality\"\nupdate-view
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
6
152
178
185
residents-per-job
residents-per-job
0
500
10.0
5
1
NIL
HORIZONTAL

SLIDER
6
258
179
291
quality-preference
quality-preference
-1
1
0.5
0.1
1
NIL
HORIZONTAL

MONITOR
184
82
276
127
Population
count residents
17
1
11

MONITOR
184
183
277
228
% MI
count residents with [ race = 2 ] / count residents
3
1
11

MONITOR
184
132
277
177
% MA
count residents with [ race = 1 ] / count residents
3
1
11

CHOOSER
826
10
999
55
trifs-choose
trifs-choose
"near minority" "away from majority" "low price"
2

PLOT
892
172
1210
366
Race
NIL
NIL
0.0
10.0
40.0
60.0
true
true
"" ""
PENS
"MA" 1.0 0 -2674135 true "" ""
"MI" 1.0 0 -4079321 true "" ""

SLIDER
6
187
178
220
growth-rate
growth-rate
0
.10
0.07
.01
1
NIL
HORIZONTAL

SLIDER
6
293
179
326
distance-preference
distance-preference
-1
1
0.1
.1
1
NIL
HORIZONTAL

SLIDER
7
328
181
361
price-preference
price-preference
-1
1
0.0
.1
1
NIL
HORIZONTAL

SLIDER
825
103
1000
136
maj-similarity-preference
maj-similarity-preference
0
1
0.3
.1
1
NIL
HORIZONTAL

MONITOR
308
512
395
557
NIL
n-run
17
1
11

BUTTON
184
512
304
546
NIL
reset-runs
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
184
233
277
278
# TRIFs
count jobs with [ trif = 1 ]
17
1
11

MONITOR
185
284
278
329
# NTRIFs
count jobs with [ trif = 0 ]
17
1
11

BUTTON
182
44
277
78
view zones
set view-mode \"zones\"\nupdate-view
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
6
222
179
255
diffusion-rate
diffusion-rate
0
1
0.7
.1
1
NIL
HORIZONTAL

SLIDER
8
439
181
472
majority-probability-of-moving
majority-probability-of-moving
0
1
0.2
.05
1
NIL
HORIZONTAL

SLIDER
1004
10
1176
43
majority-wealth
majority-wealth
0
100
54.0
1
1
NIL
HORIZONTAL

SLIDER
1005
84
1175
117
minority-wealth
minority-wealth
0
100
28.0
1
1
NIL
HORIZONTAL

SLIDER
1005
47
1175
80
majority-wealth-stdev
majority-wealth-stdev
0
100
41.0
1
1
NIL
HORIZONTAL

SLIDER
1006
121
1175
154
minority-wealth-stdev
minority-wealth-stdev
0
100
41.0
1
1
NIL
HORIZONTAL

SLIDER
6
82
178
115
starting-majority
starting-majority
0
1000
140.0
5
1
NIL
HORIZONTAL

SLIDER
6
117
178
150
starting-minority
starting-minority
0
1000
235.0
5
1
NIL
HORIZONTAL

SLIDER
8
475
181
508
minority-probability-of-moving
minority-probability-of-moving
0
1
0.2
.05
1
NIL
HORIZONTAL

MONITOR
185
384
277
429
% lands occu.
round ((1 - ( count land with [ not any? jobs-here and not any? residents-here ] / (( (max-pxcor * 2 ) + 1) * (( ( max-pycor * 2 ) + 1 ))))) * 100 )
17
1
11

SLIDER
8
365
180
398
quality-exp-decay-rate
quality-exp-decay-rate
1
10
1.5
.5
1
NIL
HORIZONTAL

SLIDER
9
401
181
434
price-exp-decay-rate
price-exp-decay-rate
1
10
7.0
.5
1
NIL
HORIZONTAL

SLIDER
825
138
1000
171
min-similarity-preference
min-similarity-preference
0
1
0.3
.1
1
NIL
HORIZONTAL

SWITCH
399
511
569
544
export-results
export-results
1
1
-1000

PLOT
892
368
1211
595
Quality Detail
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"richmaj" 1.0 0 -1604481 true "" ""
"midmaj" 1.0 0 -2674135 true "" ""
"poormaj" 1.0 0 -10873583 true "" ""
"richmin" 1.0 0 -5516827 true "" ""
"midmin" 1.0 0 -13791810 true "" ""
"poormin" 1.0 0 -15582384 true "" ""

CHOOSER
825
57
1000
102
ntrifs-choose
ntrifs-choose
"low price" "near majority"
0

BUTTON
9
548
87
582
Profiler
setup                  ;; set up the model\nprofiler:start         ;; start profiling\nrepeat 30 [ go ]       ;; run something you want to measure\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset         ;; clear the data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
683
11
821
56
cleanup-policy
cleanup-policy
"high price" "high pollution" "near minority" "near majority"
3

SWITCH
684
60
821
93
nfa?
nfa?
1
1
-1000

SWITCH
684
135
820
168
race-in-gent
race-in-gent
0
1
-1000

MONITOR
185
432
277
477
gentrifiable land
count land with [ gentrifiable = 1 ] / count land
2
1
11

MONITOR
281
432
384
477
gentrified land
count land with [ gentrified = 1 ] / count land
2
1
11

SLIDER
8
512
180
545
density-preference
density-preference
0
20
10.0
1
1
NIL
HORIZONTAL

MONITOR
450
432
507
477
wealth
mean [ wealth ] of residents
2
1
11

MONITOR
388
432
445
477
price
mean [ price ] of land
2
1
11

MONITOR
185
334
278
379
total firms
count jobs with [ trif = 0 ] + count jobs with [ trif = 1 ]
17
1
11

MONITOR
512
432
629
477
gentrified blocks
count assessors with [ gent = 1 ] / count assessors
2
1
11

MONITOR
684
171
885
216
residents in gentrified areas
count residents with [ gfied  = 1 ]  / count residents
2
1
11

MONITOR
684
218
884
263
minority residents in gentrified areas
count residents with [ gfied = 1 and race = 2 ] / count residents with [ race = 2 ]
2
1
11

MONITOR
684
264
885
309
displaced rate
count residents with [ displaced = 1 ] / count residents
2
1
11

MONITOR
685
310
885
355
minority residents displaced rate
count residents with [ displaced = 1 and race = 2 ] / count residents with [ race = 2 ]
2
1
11

MONITOR
685
359
885
404
avg times minorities displaced
mean [ times-displaced ] of residents with [ race = 2 ]
2
1
11

MONITOR
685
445
885
490
residents in gentrifiable areas
count residents with [ gfiable = 1 and gfied = 0 ] / count residents
2
1
11

MONITOR
685
492
886
537
minorities in gentrifiable areas
count residents with [ gfiable = 1 and gfied = 0 and race = 2 ] / count residents with [ race = 2 ]
2
1
11

MONITOR
684
540
886
585
avg minority tenure in gentrified areas
mean [ benefit-time ] of residents with [ race = 2 ]
2
1
11

MONITOR
687
405
886
450
avg times majorities displaced
mean [ times-displaced ] of residents with [ race = 1 ]
2
1
11

SLIDER
157
572
329
605
n-districts
n-districts
0
25
10.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
************************************************  
An agent-based model of environmental injustices  
by Adam Eckerd, Heather Campbell, Yushim Kim  
September 2010

Note: The model is linked to R.  
The user must have R in their computer  
************************************************

 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 151 152 137 77 105 67 89 67 66 74 48 85 36 100 24 116 14 134 0 151 15 167 22 182 40 206 58 220 82 226 105 226 134 222
Polygon -16777216 true false 151 150 149 128 149 114 155 98 178 80 197 80 217 81 233 95 242 117 246 141 247 151 245 177 234 195 218 207 206 211 184 211 161 204 151 189 148 171
Polygon -7500403 true true 246 151 241 119 240 96 250 81 261 78 275 87 282 103 277 115 287 121 299 150 286 180 277 189 283 197 281 210 270 222 256 222 243 212 242 192
Polygon -16777216 true false 115 70 129 74 128 223 114 224
Polygon -16777216 true false 89 67 74 71 74 224 89 225 89 67
Polygon -16777216 true false 43 91 31 106 31 195 45 211
Line -1 false 200 144 213 70
Line -1 false 213 70 213 45
Line -1 false 214 45 203 26
Line -1 false 204 26 185 22
Line -1 false 185 22 170 25
Line -1 false 169 26 159 37
Line -1 false 159 37 156 55
Line -1 false 157 55 199 143
Line -1 false 200 141 162 227
Line -1 false 162 227 163 241
Line -1 false 163 241 171 249
Line -1 false 171 249 190 254
Line -1 false 192 253 203 248
Line -1 false 205 249 218 235
Line -1 false 218 235 200 144

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="200" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="70"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="minority-wealth">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satisfice">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-exp-decay-rate">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-exp-decay-rate">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density-preference">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="majority-wealth-stdev">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-similarity-preference">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-minority">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-preference">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-preference">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trifs-choose">
      <value value="&quot;low price&quot;"/>
      <value value="&quot;near minority&quot;"/>
      <value value="&quot;away from majority&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="urban">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="majority-probability-of-moving">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-majority">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minority-probability-of-moving">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-preference">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mixed-use">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minority-wealth-stdev">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zoning">
      <value value="&quot;proactive&quot;"/>
      <value value="&quot;reactive&quot;"/>
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-wealth-effect">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="majority-wealth">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maj-similarity-preference">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="residents-per-job">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
