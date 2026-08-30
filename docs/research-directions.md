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
| VLM | Vision-language model: a model that relates images or video to language |
| VLA | Vision-language-action model: a model that also predicts a robot action, maneuver, or trajectory |
| World model | A learned model that predicts possible future states or observations, often conditioned on an action |
| V2X | Vehicle-to-everything communication, including vehicle-to-vehicle and vehicle-to-infrastructure links |
| RSU | Roadside unit: fixed communication, sensing, or edge-compute equipment beside a route |
| MEC | Multi-access edge computing: applications deployed near network access, under a defined edge architecture |
| NTN | Non-terrestrial network: a radio/network path involving satellites or other non-ground platforms |
| GNSS | Global Navigation Satellite System, such as GPS, Galileo, BeiDou, or GLONASS |
| RTK | Real-time kinematic GNSS: carrier-phase positioning using corrections from a suitable reference path |
| PNT | Positioning, navigation, and timing |
| Shadow mode | Running a system live and logging its proposals without giving it actuator authority |
| ODD | Operational design domain: the conditions in which a function is intended and allowed to operate |
| HIL | Hardware-in-the-loop testing: real target hardware connected to a simulated system or environment |
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
| Add a VLA | Test constrained semantic or trajectory proposals against conventional and learned baselines, including abstention and deadline misses |
| Connect two vehicles | Determine what information is worth sharing under age, pose, bandwidth, and trust uncertainty |
| Add GNSS or a satellite link | Quantify positioning integrity or backup-link value rather than assuming “satellite” means accurate or low-latency |

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
| Foundation-model navigation and world models | Can a constrained VLA improve instruction following or unusual-scenario handling while abstaining under distribution shift? | Demonstration data, simulator, external training compute, conventional safety/control stack | Embodied AI, robot learning |
| Cooperative V2X perception and offloading | Which information or computation should move between vehicles and edge servers before it becomes stale? | Second agent or RSU, synchronized sensors, private network, edge GPU | Connected autonomy, edge systems |
| Satellite-assisted resilient PNT | Can GNSS, vision, inertial, and wheel sensing produce a trustworthy global pose and timely integrity alert? | Raw dual-frequency GNSS, reference GNSS/INS, outdoor course | Sensor fusion, resilient navigation |

The strongest application story normally chooses one primary direction and one
supporting direction. Many disconnected prototypes are less convincing than
one carefully measured question.

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

## Frontier snapshot: August 2026

The next three directions are especially active at the time of writing. “Hot”
does not mean mature, safe, or automatically suitable for this platform. Their
value is that they connect a small reproducible robot to questions now being
asked on full-size research vehicles. Their literature and benchmarks will
change quickly, so the source list and novelty claim must be refreshed before a
proposal or interview.

## 7. Later: foundation-model navigation and learned world models

### Research question

Can a constrained vision-language-action (VLA) system improve instruction
following on predeclared held-out scenarios, and do calibrated abstention and
independent gating keep predeclared risk metrics no worse than a matched-speed
baseline within a defined ODD?

A related but separable question is whether an action-conditioned learned world
model can rank short-horizon trajectory candidates or expose policy failures
better than a bicycle model and ordinary simulator. Combining a VLA, world
model, simulator, and real car without isolating their effects would make an
impressive demo but a weak experiment.

VLA is a broad label. Some models predict robot-joint actions, some produce a
driving trajectory, and some select a high-level maneuver. A manipulation VLA
does not become a driving policy by renaming its outputs. For this project, a
hierarchical design is the defensible starting point:

```text
camera + vehicle state + language instruction
                  |
        slow semantic/VLA proposer
                  |
 discrete maneuver, local goal, or bounded trajectory + abstention
                  |
 schema, freshness, map, kinematic, and ODD checks
                  |
 conventional planner/controller + independent local safety
```

The learned model must not output hobby PWM, arbitrary CAN frames, or a direct
actuator command. It may propose `stop`, `continue`, `turn_left`, `turn_right`,
`request_help`, a local geometric goal, or a short trajectory in a versioned
schema. Every motion proposal includes its coordinate frame, creation time,
expiry, and finite time or distance horizon; `continue` cannot refresh the
command watchdog indefinitely. A deterministic validator rejects malformed,
stale, dynamically infeasible, or out-of-ODD proposals. Language explanations
can help a developer inspect a run, but a plausible explanation is not proof
that the action is safe or that the stated reasoning caused it.

### First experiment

Use a small closed-course vocabulary: follow a lane, turn at a named landmark,
stop beside an object, yield to a staged obstacle, and request help when an
instruction or scene is ambiguous.

1. Collect synchronized video, pose, instruction, operator command, selected
   trajectory, safety state, and intervention data from simulation and
   low-speed teleoperation. Record dataset consent, privacy, and model/data
   licences.
2. Split by complete route, physical environment, recording session, and
   instruction template. Adjacent frames from one run must not cross the train
   and test boundary.
3. Separate two fair comparisons. For language grounding, compare a frozen VLM
   with a learned language-conditioned policy using the same observations and
   maneuver library. For trajectory/control, give every method the same
   correctly parsed structured goal, controller, speed cap, and sensor inputs;
   compare the deterministic state machine, behavior cloning without language
   pretraining, and parameter-efficient VLA adaptation.
4. Evaluate on held-out recordings, then closed-loop simulation, then toy-car
   shadow mode during ordinary teleoperation. Only afterward consider limited
   model authority on the low-speed toy car with a spotter and independent
   stop. Keep the full-size vehicle in replay and shadow mode until its separate
   engineering and safety gates are passed.
5. Stress instruction paraphrases and contradictions, new layouts, lighting,
   occlusion, camera corruption, misleading visible text, server loss, and
   inference deadline misses.

Predeclare a primary outcome such as the fraction of tasks completed with
neither an intervention nor an ODD violation. Also report task success,
intervention, and violation rates separately, along with wrong maneuvers,
minimum clearance, off-course distance, abstention, risk-versus-coverage,
trajectory error, instruction sensitivity, 95th-percentile inference time,
memory, power, and recovery from model or server failure.

A world-model extension should compare predicted motion and policy ranking
against a calibrated vehicle model and simulator. Evaluate action fidelity,
trajectory error, collision-event prediction, calibration, and whether it
actually improves the downstream decision. Photorealistic generated video is
not an adequate result: a generated scene can look convincing while disobeying
the conditioned action or inventing another road user's response.

Training a foundation model from scratch is not a sensible first goal for one
Jetson and a small dataset. Adapt an open checkpoint on lab compute, start with
offline or simulator evaluation, and profile any compressed onboard model
under the simultaneous perception and video workload. A missing, late, or
invalid cloud/edge result must be discarded and trigger an independently
implemented safe fallback; the remote model never owns or inhibits the stop
path.

### What could become a contribution

- a constrained VLA evaluated on genuinely held-out environments, with
  calibrated abstention rather than forced action;
- evidence about which semantic goal or trajectory representations transfer
  from the toy platform to a full-size vehicle, and which do not;
- a dataset connecting language, synchronized sensor data, trajectory
  proposals, interventions, and failure labels across two vehicle scales;
- a decision-centric test showing when a learned world model is or is not
  trustworthy for trajectory ranking; or
- a dual-system architecture combining slow learned reasoning with fast,
  independently enforced vehicle constraints.

## 8. Cooperative V2X perception and deadline-aware offloading

### Research question

Under occlusion and imperfect communication, can vehicles or roadside units
share only the information that improves a downstream decision, without
trusting stale, misregistered, redundant, or malicious observations?

A companion systems question is:

> When should a vehicle run a task locally, offload it, split a model, or drop
> stale work so that useful results arrive before their deadline?

A Master's project should choose cooperative perception or scheduling as the
primary variable. A PhD project could model them jointly: the best message and
compute location depend on scene uncertainty, radio conditions, compute load,
energy, and how quickly the result loses value.

A private Wi-Fi testbed can transport prototype cooperative messages;
production campus Wi-Fi may only be passively characterized with permission.
Neither is automatically a standards-conformant V2X radio. V2X is the
application umbrella: vehicle-to-vehicle (V2V), vehicle-to-infrastructure
(V2I), vehicle-to-pedestrian (V2P), and vehicle-to-network (V2N) have different
participants and link assumptions. ITS-G5/IEEE 802.11p or 802.11bd, LTE-/NR-V2X
direct sidelink over PC5, and cellular-network paths over Uu must be named and
distinguished. Generic Wi-Fi or 5G connectivity should not be relabeled as one
of those technologies.

### First cooperative-perception experiment

Reproduce an occluded intersection with movable screens. The second agent can
initially be another synchronized camera/Jetson or a fixed roadside unit.
Establish an independently calibrated reference transform and time base, report
their uncertainty, and define how object truth and first-detection time are
measured before injecting pose, clock, or extrinsic faults. Compare:

1. ego sensing only;
2. centralized raw image or point-cloud sharing;
3. object- or track-level late fusion;
4. compressed intermediate-feature sharing; and
5. age-, pose-uncertainty-, trust-, and bandwidth-aware selection.

Compare representations under matched bandwidth and result-deadline budgets,
or report their complete quality-versus-bitrate frontier. Vary link delay/loss,
clock offset, sensor extrinsics, peer-pose error, source dropout, heterogeneous
sensor quality, and a predeclared fault/attacker model covering replay, bounded
pose falsification, phantom or missing objects, compromised credentials, and
attacker knowledge. Measure time-to-first-detection, precision/recall,
object-position error, false fused objects, useful warning margin, age of
information, tail latency, bytes per useful detection, compute, and energy.
Report residual clock-synchronization error with age metrics. Signatures can
establish message origin and integrity but cannot prove that a sensor
observation is true, so fusion still needs plausibility, freshness, and
uncertainty checks.

### First offloading experiment

Replay identical timestamp-preserved logs on the Jetson and a lab GPU server,
then repeat live over controlled private-network traces. Candidate work includes
object detection, global map optimization, loop closure, dense-map updates, and
occasional VLM reasoning. Compare local-only, remote-only, one fixed split, a
simple threshold policy, a deadline/uncertainty-aware scheduler, and an offline
oracle that knows the future trace as an unattainable upper bound. Tune or train
policies on separate workloads and network traces, then evaluate on held-out
scenes and traces.

Account for capture, encoding, upload, queueing, inference, download, decoding,
and result integration—not only server inference time. Measure task quality,
deadline-hit rate, result age, tail end-to-end latency, bytes and joules per
useful result, Jetson temperature, and recovery after link/server loss. An
ordinary workstation on a LAN is an edge prototype, not a standards-conformant
multi-access edge computing (MEC) deployment, and it demonstrates no 5G
property. MEC is multi-access and is not synonymous with 5G. State whether an
energy measurement covers the vehicle alone or also the network and server.

Local tracking, command freshness, braking, actuator limits, watchdogs, and
every motion-safety decision must work with every peer and server absent.
Offloaded results are enhancements that can expire and be discarded, never
authority that prevents a local stop.

### What could become a contribution

- task-oriented communication that maximizes useful warning or planning value
  per byte rather than raw perception score;
- uncertainty-aware fusion that degrades predictably under pose, time, and
  source faults;
- a causal offloading policy evaluated against a future-knowing oracle and
  explicit end-to-end deadlines;
- a cross-scale result showing which conclusions survive the move from two
  small agents on Wi-Fi to automotive sensors, a roadside unit, and a real
  vehicle; or
- a reproducible adversarial/fault benchmark for cooperative perception.

Use only approved radio equipment and spectrum. Do not inject impairment into
the production campus network. Minimize and authenticate transmitted data,
enforce anti-replay and least privilege, and retain only approved records;
structured objects and trajectories can still expose identities, locations, or
routines. Isolate cooperative interfaces from CAN and the vehicle-control
network through a narrow gateway. Dedicated 5.9 GHz or C-V2X experiments need
the applicable spectrum and institutional approval.

## 9. Satellite-assisted resilient positioning and connectivity

“Satellite” hides three different topics. They should not be presented as one
technology:

1. **GNSS/PNT:** satellite measurements provide global position and time.
2. **Non-terrestrial networking (NTN):** a satellite link may provide backup
   communication or delayed data transfer.
3. **Earth-observation or satellite-map priors:** overhead imagery may provide
   coarse, potentially stale context for a large outdoor route.

The first is the most credible near-term research direction for a lab vehicle.
The current indoor ceiling-facing demonstration gains nothing from GNSS.

### Research question

Can raw multi-constellation GNSS, visual-inertial odometry, and wheel
measurements produce a globally aligned pose plus a calibrated warning when the
position should not be trusted, when evaluated against an independent reference
trajectory?

This changes the target from “lower average error” to positioning integrity:
does the reported uncertainty or protection level actually bound error, and how
quickly does the system alert when multipath, blockage, interference, or a
fault makes the estimate misleading?

### First experiment

1. Add a raw dual-frequency GNSS receiver only after moving to an approved
   outdoor platform. Evaluate against a separately configured reference-grade
   trajectory, characterize its calibration and uncertainty, and acknowledge
   common-mode GNSS or multipath error. Where possible, cross-check it with
   surveyed markers, total station, motion capture, or a post-processed
   reference.
2. Record synchronized raw GNSS, camera, IMU, wheel/vehicle state, correction
   status, satellite geometry, and environment labels across open sky, tree
   cover, building canyons, and covered transitions.
3. Compare standalone GNSS; RTK with an approved base/correction path; Galileo
   High Accuracy Service, which is a precise-point-positioning correction
   service with receiver-support and convergence requirements to measure;
   local visual-inertial or wheel odometry; loose fusion; and tightly coupled
   fusion.
4. Predeclare the ODD, alert limit, time-to-alert requirement, integrity-risk
   target, fault model, and exclusion rules. Use recorded or synthetic
   measurement faults, or an institutionally authorized shielded RF facility;
   never radiate GNSS jamming or spoofing signals.

Measure horizontal and heading error, availability and continuity, error at
alert, protection-level calibration, false and missed alerts, time to alert,
reacquisition after outage, compute, and power. Report protection-level
exceedances with confidence intervals. A limited route dataset can test
empirical calibration; it cannot establish rare-event automotive integrity or
certification. Galileo Open Service Navigation Message Authentication (OSNMA)
can authenticate selected navigation data, not the complete position/time or
ranging solution, and it does not prevent every form of spoofing, multipath,
receiver fault, or jamming.

### NTN and satellite-map extensions

An NTN link is more credible for supplementary health or emergency-message
delivery, map/model synchronization, and delayed log upload than for low-level
steering or as the sole emergency path. 3GPP NR-/IoT-NTN, a proprietary
satellite-IP terminal, and ordinary satellite backhaul are not interchangeable.
Begin with measured or disclosed network traces and compare terrestrial-only
against terrestrial-plus-NTN failover. A trace emulator validates scheduling
and failover logic, not antenna visibility, handover, terminal RF behavior, or
real coverage. Report maximum outage, failover and recovery time, delivery
probability before an application deadline, energy, and data cost. No remote or
satellite path belongs in the local braking or watchdog authority.

LEO positioning and satellite Earth-observation localization remain longer-term
topics. Current demonstration programmes are not operational guarantees. A
satellite image may provide a coarse semantic or route prior for an outdoor
vehicle, but its age and resolution make it unsuitable for current obstacle
avoidance.

### What could become a contribution

- a positioning-integrity monitor tested through real satellite visibility
  transitions rather than only average open-sky accuracy;
- a factor-graph or filter that exploits partial GNSS without contaminating
  locally accurate odometry;
- a cross-sensor time-integrity method useful to both localization and V2X;
- an evidence-based NTN failover policy for noncritical vehicle data; or
- a negative result identifying when a satellite service adds no useful value
  for the selected operating environment.

## Recommended first study

There are two credible strategies, and they should not be confused:

| Strategy | Best first evidence | Why choose it |
| --- | --- | --- |
| Build evidence immediately on the present platform | Freshness-aware teleoperation | The hardware and network constraint already exist, and the study can begin before autonomy |
| Bridge into a well-equipped vehicle laboratory | Cooperative perception/offloading, constrained VLA shadow evaluation, or GNSS integrity | Verified access to a suitable second vehicle/RSU, edge GPU, automotive sensors, HIL rig, or reference GNSS/INS makes the comparison scientifically meaningful |

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

For a target group that already has a full-size research vehicle and
industry-grade equipment, a stronger frontier proposal is:

> **Cross-scale evaluation of cooperative driving intelligence:** build one
> stable perception/data interface on the toy platform, evaluate a narrow VLA,
> V2X, offloading, or positioning-integrity hypothesis in replay and simulation,
> and then probe cross-platform transfer in shadow mode on the lab vehicle.

The proposal should name one primary mechanism. “Combine VLA, V2X, edge, and
satellite on a real car” is a vision statement, not an experiment. The
[laboratory-vehicle engineering roadmap](lab-vehicle-roadmap.md) describes the
platform gates that must precede real-car actuation.

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
| Embodied AI / autonomous-driving ML | 4, 6, and 7 | VLA, hierarchical policy, world model, sim-to-real, abstention, shadow mode |
| Connected vehicles / intelligent transport | 1, 4, and 8 | V2X, cooperative perception, semantic communication, edge scheduling |
| Resilient navigation / satellite systems | 3 and 9 | GNSS integrity, multisensor fusion, PNT, NTN failover |

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

## Selected primary literature and official starting points

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

### Foundation models, learned driving, and world models

- Kim et al., [“OpenVLA: An Open-Source Vision-Language-Action
  Model”](https://arxiv.org/abs/2406.09246), CoRL 2024. This is an accessible
  VLA and parameter-efficient adaptation reference, but its demonstrated action
  domain is robot manipulation rather than driving.
- Cheng et al., [“NaVILA: Legged Robot Vision-Language-Action Model for
  Navigation”](https://navila-bot.github.io/), RSS 2025. Its two-level design
  separates semantic VLA commands from a faster locomotion policy; it does not
  establish safety or transfer to an Ackermann vehicle.
- Hwang et al., [“EMMA: End-to-End Multimodal Model for Autonomous
  Driving”](https://waymo.com/research/emma/), 2024. The authors map camera data
  to several driving outputs and explicitly identify short temporal context,
  missing LiDAR/radar, and compute cost as limitations.
- Arai et al., [“CoVLA: Comprehensive Vision-Language-Action Dataset for
  Autonomous Driving”](https://openaccess.thecvf.com/content/WACV2025/html/Arai_CoVLA_Comprehensive_Vision-Language-Action_Dataset_for_Autonomous_Driving_WACV_2025_paper.html),
  WACV 2025. It provides a public starting point for paired driving video,
  language, and trajectory work.
- Arai et al., [“ACT-Bench: Towards Action Controllable World Models for
  Autonomous Driving”](https://arxiv.org/abs/2412.05337), 2024 preprint. It
  motivates evaluating whether a generated future follows the conditioned ego
  action, not merely whether the video looks realistic.
- Wang et al., [“Alpamayo-R1: Bridging Reasoning and Action Prediction for
  Generalizable Autonomous Driving in the Long
  Tail”](https://research.nvidia.com/labs/avg/publication/wang.luo.etal.arxiv2025/),
  2025 preprint. It is a recent driving-VLA research reference, not settled
  evidence for public-road deployment. The
  [official repository](https://github.com/NVlabs/alpamayo) identifies newer
  model versions and explicitly describes the release as a research building
  block rather than a complete, automotive-validated driving stack.
- NVIDIA et al., [“OmniDreams: Real-Time Generative World Model for Closed-Loop
  Autonomous Vehicle
  Simulation”](https://research.nvidia.com/publication/2026-06_nvidia-omnidreams-real-time-generative-world-model-closed-loop-autonomous),
  2026 whitepaper. It is a recent action-conditioned closed-loop world-model
  reference; its reported preliminary results are not vehicle safety
  validation.

### Cooperative vehicles and edge offloading

- Xu et al., [“V2X-ViT: Vehicle-to-Everything Cooperative Perception with
  Vision Transformer”](https://arxiv.org/abs/2203.10638), ECCV 2022. It is a
  reproducible baseline for fusion under asynchronous messages, pose errors,
  and heterogeneous agents.
- Lu et al., [“An Extensible Framework for Open Heterogeneous Collaborative
  Perception”](https://openreview.net/forum?id=KkrDUGIASk), ICLR 2024. HEAL is
  a useful reference when the car and roadside unit have different sensors or
  models.
- Zimmer et al., [“TUMTraf V2X Cooperative Perception
  Dataset”](https://openaccess.thecvf.com/content/CVPR2024/papers/Zimmer_TUMTraf_V2X_Cooperative_Perception_Dataset_CVPR_2024_paper.pdf),
  CVPR 2024. It supplies real vehicle and roadside sensor data rather than only
  a simulated cooperative scene.
- Zaki et al., [“Quality-Aware Task Offloading for Cooperative Perception in
  Vehicular Edge Computing”](https://doi.org/10.1109/TVT.2024.3444591), *IEEE
  Transactions on Vehicular Technology*, 2024. It provides a
  value-of-information baseline for deciding what cooperative work to offload.
- [3GPP TS 23.287](https://portal.3gpp.org/desktopmodules/Specifications/SpecificationDetails.aspx?specificationId=3578)
  distinguishes direct PC5 and network Uu paths for V2X architecture;
  [ETSI TS 103 324](https://www.etsi.org/deliver/etsi_ts/103300_103399/103324/02.01.01_60/ts_103324v020101p.pdf)
  defines a Collective Perception Service and message. These standards give
  terminology and message context; using campus Wi-Fi does not claim radio
  conformance.
- [3GPP TS 23.558](https://portal.3gpp.org/desktopmodules/Specifications/SpecificationDetails.aspx?specificationId=3723)
  describes 5G edge-application architecture, while
  [ETSI GS MEC 030](https://www.etsi.org/deliver/etsi_gs/MEC/001_099/030/03.03.01_60/gs_MEC030v030301p.pdf)
  defines a V2X Information Service API for MEC. They prevent a LAN workstation
  experiment from being mislabeled as standards-conformant MEC.

### Satellite-assisted navigation and connectivity

- Cao, Lu, and Shen, [“GVINS: Tightly Coupled GNSS–Visual–Inertial Fusion for
  Smooth and Consistent State
  Estimation”](https://doi.org/10.1109/TRO.2021.3133730), *IEEE Transactions on
  Robotics*, 2022. It is an open algorithmic baseline for globally anchored
  local estimation through intermittent GNSS.
- The EU Agency for the Space Programme documents the free
  [Galileo High Accuracy Service](https://www.euspa.europa.eu/galileo-has), its
  correction channels, and its nominal service claims. Receiver support and
  observed performance still need experimental verification.
- The European GNSS Service Centre's official
  [Galileo FAQ](https://www.gsc-europa.eu/galileo/faq) explains that OSNMA
  authenticates navigation data rather than the complete position/velocity/time
  solution and does not protect against every spoofing form or jamming.
- 3GPP's official [NR-NTN work
  item](https://portal.3gpp.org/desktopmodules/WorkItem/WorkItemDetails.aspx?workitemId=860046)
  records the Release 17 non-terrestrial-networking work. It is standards
  context, not a performance promise for an unspecified commercial terminal.
- ESA's [Celeste LEO-PNT programme](https://www.esa.int/Applications/Satellite_navigation/Celeste)
  is useful evidence that low-Earth-orbit PNT is active research and
  demonstration work. It must not be described as an operational service
  already available to this car.

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
- [Progression to a full-size laboratory vehicle](lab-vehicle-roadmap.md)
- [Reproducibility and portability boundary](portability.md)
