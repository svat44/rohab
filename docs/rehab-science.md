# What the rehab has to get right

Research notes for redesigning Rohab's exercises and measurements. Each
section gives what the evidence says, then what it means for the app.
Sources are linked inline; most are peer-reviewed, a few are preprints or
secondary summaries and are marked as such.

## 1. What is actually wrong with the hand after stroke

- **Weakness, mainly of finger extension, is the main problem.** In chronic
  hemiparesis, weakness (grip and isometric finger extension) explained most
  of the impairment; passive stiffness and resting flexion torque mattered
  less ([Kamper et al., PubMed 16935065](https://pubmed.ncbi.nlm.nih.gov/16935065/)).
- **Opening the hand is harder than closing it.** Voluntary activation of
  the finger extensor (EDC) is more impaired than the flexor (FDS) in severe
  cases ([Topics in Stroke Rehab](https://www.tandfonline.com/doi/full/10.1179/1945511915Y.0000000023)).
- **Severe hands barely move.** In 95 people with severe chronic impairment,
  grip was about 12% of the other hand and only 6 could produce any net
  extension force at all
  ([PubMed 33657985](https://pubmed.ncbi.nlm.nih.gov/33657985/)).
- **Flexors fight the opening.** Flexor co-activation and spasticity work
  against voluntary extension
  ([Raghavan review](https://www.researchgate.net/profile/Preeti-Raghavan/publication/6236989_The_nature_of_hand_motor_impairment_after_stroke_and_its_treatment/links/54308cf60cf27e39fa9e191c/The-nature-of-hand-motor-impairment-after-stroke-and-its-treatment.pdf);
  [PMC8258409](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8258409/)).
- **Moving one finger alone is lost separately.** Individuation suffers from
  both reduced control and a pull toward flexing all fingers together
  ([eLife reviewed preprint](https://elifesciences.org/reviewed-preprints/91495v1),
  not yet final).

**What this means for Rohab**

- "Open your hand fully" assumes the very ability many patients lack. The
  main outcome to track is **active finger extension**: how far the fingers
  open by the patient's own effort.
- Exercises must be graded. A severe hand needs tasks scored on a few degrees
  of change; a mild hand needs individuation and speed.
- Counting a rep at 80% / 20% of a personal range breaks down when the range
  is tiny: 80% of 6 degrees is tracking noise. A rep needs a minimum absolute
  movement too. One reach-to-grasp trial required at least 10 degrees of
  voluntary wrist and finger extension to take part
  ([PMC5683854 table](https://pmc.ncbi.nlm.nih.gov/articles/PMC5683854/table/T3)).

## 2. How much practice

- In 312 observed therapy sessions, upper-limb practice averaged **32
  repetitions** per session
  ([Lang et al. 2009](https://www.researchgate.net/publication/26867337_Observation_of_Amounts_of_Movement_Practice_Provided_During_Stroke_Rehabilitation)).
- Protocols that asked for **300+ repetitions in an hour** (3 tasks x 100)
  were feasible, averaging 322
  ([dose-response trial](https://www.researchgate.net/publication/305627913_Dose-response_of_task-specific_upper_limb_training_in_people_at_least_6_months_post_stroke_A_Phase_II_single-blind_randomized_controlled_trial_Dose-response_of_upper_limb_motor_training);
  [proof of concept](https://www.researchgate.net/publication/43348346_Translating_Animal_Doses_of_Task-Specific_Training_to_People_With_Chronic_Stroke_in_1-Hour_Therapy_Sessions_A_Proof-of-Concept_Study)).
  The best human dose is still unknown; 300 is a working target, not a
  proven threshold.
- GRASP, a self-run graded program, prescribes about an hour a day in levels
  and improved arm function in a 103-person RCT
  ([PubMed 19359633](https://pubmed.ncbi.nlm.nih.gov/19359633/);
  [instructor manual](https://med-fom-neurorehab.sites.olt.ubc.ca/files/2021/05/GRASP-Instructor-Manual_v2.1_May-2021.pdf)).
  Evidence for home programs is thinner
  ([review](https://pure.ulster.ac.uk/en/publications/the-graded-repetitive-arm-supplementary-program-grasp-a-systemati/)).

**What this means for Rohab:** 10 reps is a warm-up, not a session. The app
should count **reps per day** toward a goal that starts low (for example
100) and grows toward about 300, split into short sets with rest.

## 3. How people learn movement again

Core principles: practice that is **specific, graded, variable and active,
with feedback**
([Maier et al., Frontiers 2019](https://www.frontiersin.org/articles/10.3389/fnsys.2019.00074/pdf);
[PMC9907222](https://pmc.ncbi.nlm.nih.gov/articles/PMC9907222)).
Feedback about the result (knowledge of results) is one of the listed
principles; vague feedback helps little. Fatigue shows up as compensation,
and rest intervals belong in the plan.

**What this means for Rohab**

- **Specific:** practise grasps used in daily life (cylinder, hook, pinch),
  not only open/close in the air.
- **Graded:** levels, moved up or down from measured performance.
- **Variable:** mix tasks within a session.
- **Feedback:** after each set, show what was achieved in plain numbers
  ("Best opening today: 42 degrees. Last week: 35 degrees."). A count alone
  is not useful feedback.
- **Fatigue:** if the movement in later reps shrinks well below the first
  reps, suggest a rest instead of pushing on.

## 4. Cheating movements (compensation)

- **Tenodesis:** bending the wrist down makes the fingers straighten
  passively; bending it up makes them curl
  ([Tenodesis grasp](https://en.wikipedia.org/wiki/Tenodesis_grasp)). A
  patient can "open" the hand this way without using the finger extensors.
- The Fugl-Meyer assessment does not allow compensation with other body
  parts ([FMA-UE manual](https://www.gu.se/sites/default/files/2026-03/International%20agreed%20manual%20Fugl-Meyer%20Assessment-Upper%20Extremity%20FMA-UE.pdf)).

**What this means for Rohab:** watch the wrist. MediaPipe's hand model has
no forearm, so it can't see wrist bend on its own. Options: Holistic
Landmarker (pose plus hands in one pass, available in `mediapipe_vision`)
gives the elbow and wrist; or the forearm rests flat on the table and the
hand's tilt is checked against that. A rep made by bending the wrist should
not count, and the app should say "Keep your wrist straight."

## 5. What a normal hand can do (reference ranges)

Active flexion, index finger: MCP about 86 degrees, PIP about 97-104, DIP
about 68; total active motion (TAM: MCP + PIP + DIP flexion minus any lack
of full extension) about 310 degrees
([Indian J Plast Surg 2024](https://www.thieme-connect.com/products/ejournals/html/10.1055/s-0044-1788593);
[PMC4372184 table](https://pmc.ncbi.nlm.nih.gov/articles/PMC4372184/table/tbl3)).
Norms vary by population, so the patient's **other hand** is the better
reference.

**What this means for Rohab:** measure and report real joint angles in
degrees, per finger, and compare with the patient's own unaffected hand and
their own history. Not an abstract "openness %".

## 6. How accurate the camera can be

- Best case: one index-finger PIP study with a **side view** reached about 4
  degrees RMSE against an electrogoniometer
  ([JBPE](https://jbpe.sums.ac.ir/article_51738.html)).
- Typical phone use: about -2 +/- 9 degrees against a goniometer
  ([summary in PMC11274637](https://pmc.ncbi.nlm.nih.gov/articles/PMC11274637/)).
- Worst case: against Vicon motion capture, MediaPipe joint angles had about
  22.5 degrees RMSE, worst at the PIP
  ([Sensors 2025](https://www.mdpi.com/1424-8220/25/18/5716)).
- MCP flexion is hard to measure from landmarks, and the DIP landmark is not
  anatomically exact
  ([PMC11274637](https://pmc.ncbi.nlm.nih.gov/articles/PMC11274637/)).
  No study validated MediaPipe finger angles in stroke patients.
- MediaPipe also gives **world landmarks**: 3D coordinates in metres around
  the hand's centre
  ([MediaPipe Hands docs](https://github.com/google/mediapipe/blob/master/docs/solutions/hands.md)).
  Self-occlusion (a closed fist) is the main source of error.

**What this means for Rohab**

- Compute angles from **world landmarks**, not the flat image coordinates
  the current code uses. Image coordinates foreshorten fingers that bend
  toward the camera, which is exactly what "palm facing the phone" causes.
- Prefer a **side view** of the hand for flexion and extension, and check
  the view before counting.
- Treat angles as **plus or minus about 10 degrees**: good for trends and
  counting, not for diagnosis. Say so on screen.
- Rep thresholds must sit well above that noise. Use a filter made for
  jittery tracking (One Euro filter) instead of a plain 5-frame average.

## 7. Movement quality

Smoothness measured with SPARC (spectral arc length) is the one smoothness
metric validated for stroke reach-to-grasp, with low measurement error, and
it tracks recovery over time
([JNER 2021](https://link.springer.com/doi/10.1186/s12984-021-00937-w);
[PMC11134951](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11134951/);
[PMC8461930](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8461930/)). It is a
proxy for recovery, not a direct measure.

**What this means for Rohab:** store movement speed and smoothness per rep
next to range. Progress can then show quality, not just count.

## 8. The glove: physics and evidence

- Fiber-reinforced pneumatic bending actuators bend roughly in proportion to
  pressure. Reported figures: about 85 degrees at 300 kPa; up to 131 degrees
  and 5.4 N at 350 kPa with assistance around 200 kPa; 5.1 N at 250 kPa.
  Many actuators are run safely up to about 500 kPa
  ([core.ac.uk 132281517](https://core.ac.uk/download/132281517.pdf);
  [core.ac.uk 199241804](https://core.ac.uk/download/199241804.pdf);
  [PMC9384960](https://pmc.ncbi.nlm.nih.gov/articles/PMC9384960)).
  Pressure-to-angle models exist but disagree with simulation, so each glove
  needs its own measured curve
  ([Harvard Biodesign](https://biodesign.seas.harvard.edu/resource/pdf-107);
  [Frontiers 2023](https://www.frontiersin.org/journals/bioengineering-and-biotechnology/articles/10.3389/fbioe.2023.1188996/epub)).
- An **EMG-triggered** soft glove beat dose-matched conventional practice on
  distal Fugl-Meyer, Box and Block, and active finger range in a 34-person
  RCT, with gains held at 3 months
  ([summary, Springer](https://link.springer.com/article/10.1186/s12938-026-01614-6)).
  Meta-analysis:
  ([PMC10295999](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10295999/)).
- When a glove does all the work, patients stop trying: one study measured
  essentially no voluntary effort during glove-driven grasps
  ([PMC5640819](https://pmc.ncbi.nlm.nih.gov/articles/PMC5640819/)).

**What this means for Rohab**

- The mock's 40 kPa target and 80 kPa limit are far below typical working
  pressures (about 100-300 kPa). Real values must come from the glove's
  actuators.
- Targets should be set as **finger angle**, using a per-glove measured
  pressure-to-angle curve, with pressure as the means.
- Keep the EMG trigger: the patient must start the movement. Lower the
  assistance as the patient's own range grows (assist as needed).

## 9. What to change in the app

| Today | Change |
| --- | --- |
| Angles from normalized image coordinates | World landmarks (metres, 3D); per-joint MCP, PIP, DIP angles; One Euro filter |
| "Openness %" | Degrees per joint and TAM per finger, against the other hand |
| 6 s open/close calibration | Baseline test of both hands that sets the starting level |
| 3 exercises for a near-normal hand | Levels: (1) mass flexion/extension with any measurable movement; (2) functional grasps: cylinder, hook, thumb, pinch; (3) individuation, opposition sequence, speed |
| Rep = 80% then 20% then 80% of range | Per-person thresholds **and** a minimum change in degrees above tracking noise |
| 10 reps per exercise | Daily rep goal (start about 100, grow toward 300) in sets with rest |
| Count only | Per-set feedback in degrees against last time; speed and smoothness stored |
| No compensation check | Wrist watched (Holistic Landmarker or forearm-on-table check); wrist-driven reps don't count |
| Palm facing camera | Side view for flexion/extension; view checked before counting |
| Mock glove 40 kPa | Real actuator range; targets in degrees via a measured pressure-to-angle curve |
| No safety check-in | Pain 0-10 before and after; stop and advise if pain rises |

Not changed: Rohab does not diagnose, score Fugl-Meyer, or replace a
therapist. Measurements are for practice and trends.
