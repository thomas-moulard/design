---
layout: default
title: Clock and Time
permalink: articles/clock_and_time.html
abstract:
  This article describes the ROS primitives to support programming which can run both in realtime as well as simulated time.
published: true
author: '[Tully Foote](https://github.com/tfoote)'
---

* This will become a table of contents (this text will be scraped).
{:toc}

# {{ page.title }}

<div class="abstract" markdown="1">
{{ page.abstract }}
</div>

Original Author: {{ page.author }}


## Background

Many robotics algorithms inherently rely on timing as well as synchronization.
To this end we require that nodes running in the ROS network have a synchronized system clock such that they can accurately report timestamps for events.

There are however several use cases where being able to control the progress of the system are important.

## Use cases requiring time abstraction

When playing back logged data it is often very valuable to support accelerated, slowed, or stepped control over the progress of time.
This control can allow you to get to a specific time and pause the system so that you can debug it in depth.
It is possible to do this with a log of the sensor data, however if the sensor data is out of synchronization with the rest of the system it will break many algorithms.

Another important use case for using an abstracted time source is when you are running logged data against a simulated robot instead of a real robot.
Depending on the simulation characteristics, the simulator may be able to run much faster than realtime or it may need to run much slower.
Running faster than realtime can be valuable for high level testing as well allowing for repeated system tests.
Slower than realtime simulation is necessary for complicated systems where accuracy is more important than speed.
Often the simulation is the limiting factor for the system and as such the simulator can be a time source for faster or slower playback.
And if the simulation is paused the system can also pause using the same mechanism.

### Challenges in using abstracted time

There are many algorithms for synchronization and they can typically achieve accuracies which are better than the latency of the network communications between devices on the network.
However, these algorithms take advantage of assumptions about the constant and continuous nature of time.

An important aspect of using an abstracted time is to be able to manipulate time.
In some cases, speeding up, slowing down, or pausing time entirely is important for debugging.

The ability to support pausing time requires that we not assume that the time values are always increasing.

When communicating the changes in time propagation, the latencies in the communication network becomes a challenge.
Any change in the time abstraction must be communicated to the other nodes in the graph, but will be subject to normal network communication latency.
This inaccuracy is proportional to the latency of communications and also proportional to the increase in the realtime factor.
If very accurate timestamping is required when using the time abstraction, it can be achieved by slowing down the realtime factor such that the communication latency is comparatively small.

The final challenge is that the time abstraction must be able to jump backwards in time, a feature that is useful for log file playback.
This is a very different behavior from most clocks, and requires developers using the time abstraction to make sure their algorithm can deal with the discontinuity.

## System Behavior

To implement the time abstraction the following approach will be used.

The time abstraction can be published by one source on the `/clock` topic.
The topic will contain the latest abstracted time for the ROS system.
If a publisher exists for the topic, it will override the system time when using the ROS time abstraction.
If `/clock` is being published, calls to the ROS time abstraction will return the latest time received from the `/clock` topic with a default of zero if nothing has been received.

If the time on the clock jumps backwards, a callback handler will be invoked and be required to complete before any calls to the ROS time abstraction report the new time.
Calls that come in before that must block.
The developer has the opportunity to register callbacks with the handler to clear any state from their system if necessary before time will be in the past.

The frequency of publishing the `/clock` as well as the granularity are not specified as they are application specific.

### No Advanced Estimating Clock

There are more advanced techniques which could be included to attempt to estimate the propagation properties and extrapolate between time ticks.
However all of these techniques will require making assumptions about the future behavior of the time abstraction.
And in the case that playback or simulation is instantaneously paused, it will break any of these assumptions.
There are techniques which would allow potential interpolation, however to make these possible it would require providing guarantees about the continuity of time into the future.
For more accuracy the progress of time can be slowed, or the frequency of publishing can be increased.
These are both 

## Public API

In each client library there will be provided an abstraction of `Time`, `Duration`, and `Rate`.
The duration abstraction will support a `sleep` function which 
It will also provide a `Timer` object which will provide periodic callback functionality using the ROS time abstraction.

### Walltime

There are several use cases where using the ROS time abstraction are inappropriate.
Example use cases for this include hardware drivers which are interacting with peripherals with hardware timeouts.
For convenience in these cases we will also provide the same API as above, but use the name `WallTime`.

`WallTime` will be directly tied to the system clock.

In nodes which require the use of `WallTime` for interacting with hardware or other peripherals it is expected that they do a best effort to isolate any `WallTime` information inside their implementation and translate external interfaces to use the ros time abstraction.

## Implementation

At the `rcl` level we will provide a time abstraction which will return the latest 'ROS time' as provided by the `/clock` topic.
It will provide the callback when time changes.

It is expected that most client libraries will provide a natural implementation of the time primitives, `Time`, `Duration`, `Rate`, and `Timer`.

## References

This is closely related to the ROS Clock and ROS Time system used in ROS 1.0.
For more information on the implementation in ROS 1.0 see:

* [ROS Clock Documentation](http://wiki.ros.org/Clock)
* [rospy Time Documentation](http://wiki.ros.org/rospy/Overview/Time)
* [roscpp Time Documentation](http://wiki.ros.org/roscpp/Overview/Time)
