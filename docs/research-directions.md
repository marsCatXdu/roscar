# Research directions from roscar

## Purpose

`roscar` is presently an engineering platform, not a research result. It runs a
reproducible RealSense, cuVSLAM, nvblox, monitoring, and RViz stack on a Jetson.
The proposed next milestone is camera-guided human teleoperation over campus
Wi-Fi with robot-local safety. Chassis control, sensor fusion, reusable mapping,
and autonomous exploration are not implemented yet.

That unfinished boundary is useful. The platform brings several difficult
systems together in one small experiment:

- visual perception can drift or fail;
- video and commands share an imperfect wireless network;
- perception, video encoding, and visualization compete for embedded compute;
- a remote human acts on delayed information; and
- software failure can become physical motion.

A coherent research theme emerges:

> How should a resource-limited mobile robot allocate sensing, communication,
> computation, human authority, and local safety when its observations and
> wireless link are imperfect?

This document suggests research questions and experiments. It does not claim
that they are novel, completed, safe for public deployment, or suitable for a
particular degree without a literature review and discussion with a potential
supervisor.

### Short glossary

| Term | Meaning here |
| --- | --- |
| ESC | Electronic speed controller: the power electronics between control input and motor |
| MCU | Microcontroller: a small independent computer used for low-level timing and safety |
| IMU | Inertial measurement unit: measures acceleration and angular velocity |
| Ackermann steering | Car-like geometry in which the front wheels steer and the vehicle cannot turn in place |
| Tail latency | Slow outliers, commonly summarized by the 95th or 99th percentile rather than the average |
| Ground truth | A more accurate reference measurement used to evaluate an estimator, with its own uncertainty reported |
| Ablation | An experiment that removes one mechanism at a time to identify what caused a result |
| Loop closure | Recognizing a previously visited place to constrain accumulated localization drift |
| Diagnostic coverage | The fraction of predefined injected fault instances or classes detected within the required time |

## Engineering is the instrument, not automatically the contribution

Building a working robot is valuable evidence of technical ability. Research
also needs a falsifiable question, comparison, and evidence that teaches
something beyond this one build.

| Engineering task | Possible research version |
| --- | --- |
| Stream camera video | Determine which adaptation policy best preserves rendered-frame freshness and operator performance under variable Wi-Fi |
| Add an IMU or wheel encoder | Detect when each sensor has become misleading, and quantify pose error at the time of detection |
| Tune VSLAM and nvblox | Allocate compute among localization, reconstruction, and video according to uncertainty and deadlines |
| Add a watchdog | Derive faults from a hazard model, inject them systematically, and measure diagnostic coverage and stop response |
| Make the car explore | Balance new-area coverage, collision risk, camera tracking quality, loop closure, and Ackermann motion constraints |

A credible project should state:

1. a narrow research question;
2. a hypothesis that could be wrong;
3. at least one serious baseline;
4. controlled variables and repeatable trials;
5. metrics chosen before looking at the result;
6. uncertainty, failure cases, and negative results; and
7. the boundary between inherited work, team work, and the student's own work.

## Candidate directions at a glance

| Direction | Candidate first study question | Extra needs | Natural research area |
| --- | --- | --- | --- |
| Network-aware teleoperation | Can frame/command freshness drive safer adaptation than throughput or signal strength alone? | Instrumented video/control path and controlled network impairment | Networked robotics, edge systems |
| Human-centered remote driving | Which interface cues reduce over-correction and misplaced confidence under delay and jitter? | Participant study and ethics approval | Human-robot interaction |
| Failure-aware state estimation | Can the robot warn that its pose is unreliable before the error becomes large? | Validated IMU, wheel sensing, and ground truth | SLAM, sensor fusion |
| Resource-aware onboard/edge perception | How should limited compute be divided among VSLAM, mapping, encoding, and UI deadlines? | Runtime instrumentation and adaptation layer | Embedded/edge robotics |
| Dependable control and fault injection | Which realistic faults escape the stop architecture, and how quickly are detected faults made safe? | Safety MCU, simulator/test rig, fault library | Dependable cyber-physical systems |
| Active perception and exploration | How should an Ackermann robot trade coverage against localization and map uncertainty? | Safe control stack, reusable SLAM, planner, simulation | Autonomous navigation |

The strongest application story normally chooses one primary direction and one
supporting direction. Six disconnected prototypes are less convincing than one
carefully measured question.

## 1. Network-aware teleoperation

### Research question

Can end-to-end application measurements of video presentation age, robot-local
command freshness, and jitter predict degraded teleoperation better than
ordinary network metrics, and can an adaptive policy improve the outcome?

This is particularly natural for `roscar`: the video travels from robot to
operator while control commands travel in the other direction. More video
bitrate can improve image detail while increasing contention, buffering, and
delay. Published robot-network experiments also show that a configuration that
maximizes throughput need not minimize control-packet delay.

### Measurements to distinguish

“Latency” must not collapse several different quantities:

| Measurement | Clock and interpretation |
| --- | --- |
| Command lease freshness | Robot receipt/expiry on one monotonic clock; suitable for enforcing the local stop without clock synchronization |
| Returned render-acknowledgement age | Robot capture time mapped to the frame ID echoed by the browser, measured when that acknowledgement returns; a conservative robot-local value that includes acknowledgement delay |
| Operator-side presentation age | Robot capture timestamp to browser presentation callback; requires characterized clock synchronization and must report residual clock-offset error |
| Glass-to-glass display latency | Physical capture to physical display, periodically validated with an LED/timer and high-speed or otherwise calibrated external measurement |
| Operator-action-to-actuator latency | Input-event time to robot actuator-request time; requires synchronized clocks or a separately validated round-trip method |

A browser callback proves that application code presented a decoded frame, not
the exact instant every display pixel was scanned out. The study should report
that measurement boundary and the uncertainty added by clock synchronization
and acknowledgement transport.

### Testable hypotheses

- Tail freshness, such as the 95th or 99th percentile application presentation
  age, predicts predeclared driving-degradation events better than average
  round-trip time or Wi-Fi signal strength.
- A policy that drops stale frames and adapts bitrate, frame rate, and the local
  throttle cap reduces interventions compared with a fixed video profile.
- Application-level separation and latest-only semantics for the command channel
  improve outcomes compared with optimizing aggregate throughput alone. They do
  not create a network quality-of-service guarantee on a campus access point.

### First experiment

Use a systems-validation stage followed by an optional operator-evaluation
stage, with these design controls:

1. **Systems validation without human claims.** Instrument capture/frame IDs,
   browser presentation callbacks and timestamps, render acknowledgements,
   clock synchronization and its measured error, command leases, robot receipt,
   actuator requests, packet loss, bitrate, and system load. Use scripted traffic,
   replay, simulation, or raised wheels.
2. **Controlled impairment.** Apply delay, jitter, loss, and bandwidth limits
   only on private test infrastructure. Approved campus measurements may
   characterize naturally occurring conditions, but injected impairments must
   not disrupt the production campus network.
3. **Factorial baselines.** Compare fixed video/fixed cap, adaptive video only,
   throttle-envelope adaptation only, and both together. Include a matched
   conservative-cap baseline so a combined policy cannot appear safer merely by
   driving more slowly.
4. **Repeatability.** Replay the same network traces, predeclare the number of
   trials and one primary systems outcome, and randomize policy order where
   order could matter.
5. **Operator evaluation only after a safe baseline.** A designated-operator
   pilot can demonstrate feasibility but cannot support population claims. A
   controlled within-subject participant study requires the ethics, sample, and
   analysis plan described in the next direction.

Systems metrics include presentation/acknowledgement age distributions, command
expiry, bitrate, CPU load, and energy. Operator metrics can include path
deviation, control reversals, completion time, and predeclared events such as a
boundary contact, watchdog stop, deviation threshold, or spotter intervention.
Report speed/progress-normalized risk as well as completion time. A predictor
should be specified before analysis and evaluated on held-out network traces or
sessions, rather than by post-hoc correlation on pooled data. Report full
distributions, clock/ground-truth uncertainty, and worst cases, not only means.

### What could become a contribution

- an open method that separates command freshness, application presentation
  age, returned-acknowledgement age, and validated glass-to-glass latency;
- a dataset connecting conditions on the tested campus route, devices, and
  dates to robot/operator outcomes, with no claim that it represents all campus
  Wi-Fi;
- a policy that jointly adapts video and the safe operating envelope; or
- evidence that a simple freshness rule outperforms a more complicated but
  network-only predictor.

This direction scales naturally from a focused Master's experiment to PhD work
on cross-layer optimization, uncertainty-aware control, or guarantees under
stochastic communication.

## 2. Human-centered remote driving

### Research question

What information should the interface show so that a remote operator behaves
well and understands when the vehicle should not be trusted?

Mean latency is not the complete experience. Delay variation, stale-but-smooth
video, field of view, and feedback about uncertainty can alter how aggressively
someone drives. A technically correct status panel can still overload or
mislead its user.

### First experiment

Compare a small number of interfaces under replayable delay/jitter profiles:

1. forward video only;
2. video plus frame-age, connection, and safety-state indicators; and
3. the same display plus a short-horizon vehicle-footprint or trajectory overlay
   from the measured Ackermann model.

Start with a simulator. A later counterbalanced participant study could measure
course completion, boundary contacts, path deviation, steering reversals,
reaction to a forced video freeze, perceived workload, confidence, and trust.
The overlay should be physically grounded and clearly marked as a prediction;
synthetic “future video” is a much harder safety and perception problem.

### Research discipline

Human studies require institutional ethics review where applicable, informed
consent, a participant-risk assessment, anonymized data, and a sample-size and
analysis plan agreed before collection. Predeclare the primary outcome and the
method for handling multiple subjective comparisons. Friends or colleagues may
give formative usability feedback, but convenience testing is not confirmatory
evidence for a population claim.

This direction suits a human-robot interaction or human-computer interaction
supervisor. A Master's project can compare carefully chosen interfaces; a PhD
could study personalized assistance, calibrated trust, or shared control under
uncertain communication.

## 3. Failure-aware visual-inertial-wheel estimation

### Research question

Can a low-cost robot recognize that its pose estimate is becoming untrustworthy
before the position error exceeds an operational limit?

The current cuVSLAM configuration is odometry-only. It can drift, and the D435i
IMU is currently disabled. The chassis has no software-integrated wheel encoder.
Those are limitations, but also an experiment design: visual texture, blur,
occlusion, vibration, wheel slip, clock offset, and sensor bias fail in different
ways.

### First experiment

1. Build a repeatable dataset with current stereo odometry and reference poses
   from motion capture, a calibrated overhead camera, or a surveyed layout of
   fiducial markers. Calibrate that reference system and report its uncertainty;
   “ground truth” is not automatically error-free.
2. Vary one factor at a time: low texture, lighting, lens occlusion, rapid turn,
   vibration, dropped frames, and timestamp delay.
3. After independent validation, add D435i IMU data and wheel measurements.
   Calibrate sensor extrinsics and time offsets, then inject wheel scale error,
   dropout, and low-traction slip without contaminating the reference system.
4. Compare fixed fusion against residual-based rejection/down-weighting and an
   explicit “odometry not trustworthy” output.

Accuracy metrics such as absolute and relative trajectory error are necessary
but insufficient. Also measure time to detect, false-alarm and missed-detection
rates, precision/recall or detection curves over multiple fault severities, pose
error at alarm, availability/continuity through tracking gaps, relocalization,
calibration convergence, recovery time, and compute cost. Define the operational
error/alarm threshold before collecting the evaluation data.

### What could become a contribution

- a small, well-labeled multimodal failure dataset;
- an online calibration or health-estimation method for inexpensive sensors;
- a principled degraded-mode trigger for remote operation; or
- an analysis showing which failures cannot be diagnosed with the available
  sensors.

The intellectually strong framing is not merely “sensor fusion improves
accuracy.” It is “the robot estimates when it does not know where it is.”

## 4. Resource-aware onboard and edge perception

### Research question

How should one Jetson allocate finite CPU, GPU, memory, power, and thermal
headroom among localization, dense reconstruction, software video encoding,
monitoring, and local visualization?

This project already exposes the conflict. CuVSLAM and nvblox use the GPU, RViz
renders locally, and camera streams consume memory bandwidth. Orin Nano has no
NVENC engine, so an onboard H.264 path would initially use CPU software encoding
unless camera-native or external compression is selected. A static configuration
that is healthy in one scene may miss deadlines after heating, map growth, or
network change.

### First experiment

Compare:

- the current fixed configuration;
- simple threshold rules; and
- an adaptive scheduler that changes only safe, declared knobs such as video
  profile, nvblox update rate/map extent, visualization, or nonessential
  logging.

Never reduce the local command watchdog or stop path to save compute. Measure
pose update rate, tracking loss, mesh freshness, rendered-video age, CPU/GPU and
memory use, temperature, power, and recovery from induced contention. Replay
the same timestamp-preserved sensor data with identical configuration and a
declared thermal initial state when comparing policies so scene difficulty is
controlled. Repeat runs because timing-driven pipelines need not replay
deterministically.

Edge-assisted SLAM is a later variant: expensive global work could run on a
campus edge server, but local tracking and every motion-safety function must
survive server or Wi-Fi loss. This can grow from a Master's systems evaluation
to PhD work on uncertainty-aware scheduling and offloading.

## 5. Dependable control through fault injection

### Research question

Within a defined operating envelope and fault model, which single and combined
faults in a non-safety-rated Jetson, hobby ESC, servo, Wi-Fi link, and camera can
still produce unsafe propulsion, and which architecture detects and mitigates
them within a predeclared interval?

The future-integration design already proposes a robot-local state machine,
fresh command leases, rendered-frame acknowledgement, a safety MCU, and a
physical disconnect. Research begins when the failure assumptions are made
explicit and tested rather than demonstrated once.

### First experiment

Create a fault library and expected safe response for:

- Wi-Fi loss, delay, reordering, congestion, and reconnect;
- frozen video with a live control channel;
- stale or replayed commands;
- gateway, ROS node, container, or Jetson crash;
- MCU boot/reset, firmware hang, missed heartbeat, or corrupted actuator request;
- camera dropout and estimator-health alarm;
- battery sag, regulator reset, common-mode power/ground fault, and selected
  sensor faults;
- servo jam or power-rail failure; and
- ESC signal loss or stuck-on behavior, only after the exact hardware response
  is understood.

Run most campaigns in simulation or with propulsion electrically disabled.
Repeat a reviewed subset on the raised chassis and finally at very low speed in
a cordoned area. Define the safe state, reaction deadline, injected fault
instances/classes, and diagnostic-coverage denominator before testing. Measure
coverage, false stops, detection time, fault-reaction time, stop time/distance,
reset behavior, and whether any delayed message can re-arm the car. Treat the
watchdog, output inhibit, and physical disconnect as mitigations with their own
failure assumptions, not as proof that every fault is safe.

A useful result could be a reproducible fault-injection harness, evidence for a
specific safety architecture, or a catalog of residual risks. It would not be
functional-safety certification. PhD expansion could add formal state-machine
verification, compositional assurance, or probabilistic models of correlated
network/perception failures.

## 6. Later: active perception and autonomous exploration

### Research question

How should an Ackermann-steered robot choose motion that reveals new space
without sacrificing localization quality, collision margin, loop closure, or
communication quality?

Naive frontier exploration tends to reward new area. Visual SLAM also benefits
from textured views and revisiting places that constrain drift. The car cannot
turn in place, and a campus route may move it through areas with different
Wi-Fi quality. These objectives can conflict, which makes the problem more
interesting than simply connecting a frontier detector to a planner.

This is deliberately later work and outside the current human-teleoperation
scope. The current cuVSLAM mode has no reusable map or loop closure, and the
vehicle has no validated actuation or autonomous safety layer. The first
research should therefore use simulation and recorded data to compare a
coverage-only objective against perception-aware objectives. Simulation does not validate
physical collision avoidance. Autonomous motion is a separately authorized,
safety-reviewed project that begins only after remote operation and every local
stop path are repeatable.

A Master's scope might study one constrained objective, such as choosing
revisit paths that bound pose drift. A PhD scope could jointly model
localization, dense-map uncertainty, vehicle dynamics, communication, and
active information gathering.

## Recommended first study

The most distinctive near-term project is:

> **Freshness-aware teleoperation on a resource-limited robot:** determine
> whether application presentation age, conservative returned-acknowledgement
> age, and robot-local command freshness can drive video adaptation and a
> conservative throttle envelope under variable Wi-Fi.

It is a good first choice because it:

- uses the campus network constraint rather than hiding it;
- can begin safely without autonomous driving or new localization hardware;
- connects networking, embedded systems, robotics, and human factors;
- produces useful instrumentation even if the adaptive policy fails; and
- can later support every other direction in this document.

### An 8–12 week systems pilot after platform bring-up

This schedule starts only after the hardware inventory, power design, camera
mount, actuator calibration, independent watchdog, local teleoperation, video
gateway, and stop behavior in the
[future-integration plan](future-vehicle-integration.md) form a safe baseline.
Building that platform is separate engineering work and may take substantially
longer. The pilot below targets systems evidence plus, at most, a formative
designated-operator demonstration; a confirmatory participant study is a later
ethics-reviewed project.

1. **Weeks 1–2: measurement validity.** Implement frame/render acknowledgement,
   command leases, actuator timestamps, and system-load logging. Test the clocks
   and prove that buffering cannot make an old command appear fresh.
2. **Weeks 3–4: repeatable impairment.** Create private-link delay, jitter,
   loss, and bandwidth profiles. Record raw conditions and version every config.
3. **Weeks 5–6: baselines.** Evaluate fixed video and adaptive-video-only
   baselines in replay/simulation or with the chassis raised.
4. **Weeks 7–8: candidate policy.** Add a freshness-based video policy and
   throttle envelope. Include ablations so each mechanism can be judged.
5. **Weeks 9–10: controlled course.** After safety review, run repeated
   designated-operator trials at low speed with randomized policy order, a
   local spotter, and a cordoned area. Do not make population-level human claims.
6. **Weeks 11–12: analysis.** Report distributions, confidence intervals,
   failures, sensitivity to thresholds, and conditions that did not improve.

Deliverables should include a frozen container/image identifier, experiment
scripts, machine-readable logs, a data dictionary, plots generated from source,
a short demonstration, and a report that another student can reproduce.

## Building a strong application and interview story

### Show ownership precisely

For every artifact, distinguish:

- what existed before the student joined;
- what collaborators or tools produced;
- what the student designed, implemented, measured, and interpreted; and
- what remains a proposal.

Using AI tools or inherited code is not the weakness; claiming unverified work
as personal research is. Good judgment is visible when inherited assumptions are
tested, errors are corrected, and provenance is recorded.

### A useful 90-second structure

1. **System:** “I made a Jetson/D435i perception stack reproducible for a small
   car-like robot, while identifying the upstream components and team
   contributions; I am designing its safe remote-operation layer.”
2. **Constraint:** “Remote operation couples stale video, delayed commands, and
   limited embedded compute.”
3. **Observation:** state one measured surprise, not a guess.
4. **Question:** give one falsifiable research question.
5. **Method:** name the baseline, controlled variable, and primary metric.
6. **Result:** give evidence with uncertainty, or honestly say the experiment is
   proposed/in progress.
7. **Taste:** explain why safety remains local and why a simpler baseline was
   tested before a sophisticated method.

Do not memorize a claim that has not been measured. A supervisor is often more
impressed by a precise limitation and a good next experiment than by an
unqualified success story.

### Portfolio artifacts worth keeping

- one architecture diagram separating data, control, and safety authority;
- a short reproducible setup guide and pinned software/hardware manifest;
- calibration records and a photograph of each hardware revision;
- experiment protocol, raw logs, data dictionary, and analysis scripts;
- baseline and ablation plots with confidence intervals;
- failure videos paired with machine-readable timelines;
- a two-page research brief: question, related work, method, result, limits;
- a three-minute demo that includes a safe failure/recovery case; and
- a development log recording decisions and negative results.

The repository should not contain campus credentials, participant identity,
unapproved recordings, or raw video with avoidable faces/license plates.

## Matching the direction to a supervisor

| Supervisor area | Most relevant directions | Useful discussion language |
| --- | --- | --- |
| Networked robotics / wireless systems | 1 and 4 | freshness, tail latency, congestion, cross-layer adaptation |
| Human-robot interaction | 1 and 2 | workload, calibrated trust, predictive display, study design |
| SLAM / state estimation | 3 and 6 | observability, integrity, drift, loop closure, active perception |
| Embedded / edge AI systems | 1 and 4 | scheduling, thermal/power budget, offloading, deadline misses |
| Dependable cyber-physical systems | 3 and 5 | fault model, detection coverage, degraded mode, formal assurance |
| Autonomous navigation | 3 and 6 | traversability, Ackermann constraints, information-aware planning |

Before approaching someone, read several of their recent papers and identify a
specific connection and a genuine question. “I like robotics” is broad;
“I want to study whether application presentation age and robot-local command
freshness predict teleoperation risk better than network RTT” gives the
conversation something technical to test.

For a Master's application, a narrow empirical question with a strong baseline
and reproducible evaluation is enough. A PhD proposal should also explain what
could generalize beyond this car: a new model, algorithm, measurement method,
theoretical guarantee, or result replicated across platforms and environments.

## Research hygiene and safety

- Read and cite the original papers; this roadmap is not a literature review or
  evidence for a technical claim.
- Decide primary metrics and exclusions before collecting the final data.
- Pin code, configuration, container image, firmware, hardware revision, and
  random seeds where relevant.
- Keep raw observations separate from derived tables and plots.
- Preserve failures and negative results instead of tuning them out silently.
- Use simulation, replay, raised-wheel tests, and a private network before
  physical campus trials.
- Obtain campus permission for wireless testing and mobile-camera operation.
- Obtain ethics approval and consent before a research participant study.
- Use a cordoned course, low output cap, local spotter, independent watchdog,
  and physical power disconnect for every moving test.

## Selected primary literature starting points

These sources motivate the directions above; they are starting points rather
than an exhaustive or final literature review.

### Networked teleoperation and human factors

- Rady et al., [“How does Wi-Fi 6 fare? An industrial outdoor robotic
  scenario”](https://doi.org/10.1016/j.adhoc.2024.103418), *Ad Hoc Networks*,
  2024. The experiments measure streaming throughput and ROS control delay
  together under varied Wi-Fi configurations and physical conditions.
- Kaknjo et al., [“Real-Time Video Latency Measurement between a Robot and Its
  Remote Control Station: Causes and
  Mitigation”](https://doi.org/10.1155/2018/8638019), 2018. This motivates
  measuring the complete capture-to-display path rather than only packet
  round-trip time.
- Schimpe, Hoffmann, and Diermeyer, [“Adaptive Video Configuration and Bitrate
  Allocation for Teleoperated
  Vehicles”](https://doi.org/10.1109/IVWorkshops54471.2021.9669258), IEEE IV
  Workshops 2021 ([open preprint](https://arxiv.org/abs/2102.10898)). This is a
  direct example of adapting teleoperation video to variable communication
  resources.
- Liu et al., [“Investigating Remote Driving over the LTE
  Network”](https://doi.org/10.1145/3122986.3123008), *AutomotiveUI*, 2017. The
  scaled-vehicle study motivates treating delay variation and presentation as
  human-performance variables.
- Rafiei et al., [“Laboratory study on quality of experience and user experience
  for teleoperation”](https://doi.org/10.1007/s41233-025-00076-3), *Quality and
  User Experience*, 2026. This study uses a remotely controlled toy truck to
  vary latency, video quality, and field of view.
- Moniruzzaman et al., [“High Latency Unmanned Ground Vehicle Teleoperation
  Enhancement by Presentation of Estimated Future through Video
  Transformation”](https://doi.org/10.1007/s10846-022-01749-3), 2022. It is a
  useful comparison point for predictive operator displays.

### Estimation and embedded perception

- Lee et al., [“Visual-Inertial-Wheel Odometry with Online
  Calibration”](https://doi.org/10.1109/IROS45743.2020.9341161), IROS 2020. It
  provides a concrete reference for fusing raw wheel information with visual
  and inertial estimation and online calibration.
- Qin, Li, and Shen, [“VINS-Mono: A Robust and Versatile Monocular
  Visual-Inertial State
  Estimator”](https://doi.org/10.1109/TRO.2018.2853729), *IEEE Transactions on
  Robotics*, 2018. It is a useful fixed visual-inertial baseline with explicit
  initialization and failure recovery.
- Fu et al., [“Visual odometry errors and fault distinction for integrity
  monitoring”](https://doi.org/10.1007/s42401-020-00062-x), 2020. It motivates
  distinguishing ordinary measurement error from faults rather than reporting
  only average pose accuracy.
- Campos et al., [“ORB-SLAM3: An Accurate Open-Source Library for Visual,
  Visual-Inertial and Multi-Map SLAM”](https://arxiv.org/abs/2007.11898), 2021.
  It is a useful research baseline, not a drop-in replacement decision for the
  current NVIDIA stack.
- Chen, Inaltekin, and Gorlatova, [“AdaptSLAM: Edge-Assisted Adaptive SLAM with
  Resource Constraints via Uncertainty
  Minimization”](https://doi.org/10.1109/INFOCOM53939.2023.10229009), INFOCOM
  2023 ([open preprint](https://arxiv.org/abs/2301.04620)). It connects SLAM
  uncertainty with communication and compute budgets.
- Kaar et al., [“Edge-SLAM: Edge-Assisted Visual Simultaneous Localization and
  Mapping”](https://doi.org/10.1145/3561972), *ACM Transactions on Embedded
  Computing Systems*, 2023. It is a second baseline for separating local
  tracking from expensive edge work.
- Millane et al., [“nvblox: GPU-Accelerated Incremental Signed Distance Field
  Mapping”](https://arxiv.org/abs/2311.00626), 2024. It explains the embedded
  dense-mapping component already used by this project.

### Dependability and later active exploration

- Sini et al., [“A Simulation-Based Approach to Aid Development of
  Software-Based Hardware Failure Detection and Mitigation Algorithms of a
  Mobile Robot System”](https://doi.org/10.3390/s22134665), *Sensors*, 2022. It
  combines failure analysis, simulation, and fault injection on a mobile robot.
- Kim and Eustice, [“Active visual SLAM for robotic area coverage: Theory and
  experiment”](https://doi.org/10.1177/0278364914547893), *International Journal
  of Robotics Research*, 2015. It frames exploration as a balance between area
  coverage and visual-SLAM navigation performance.

## Related project documents

- [How the current perception stack works](how-it-works.md)
- [Future vehicle integration and remote-operation plan](future-vehicle-integration.md)
- [Reproducibility and portability boundary](portability.md)
