# Presentation

This is the repository of the DALSim project (Dynamic Graphs and Agents for Logistics Simulations).

You can find a wiki (in french) here: [https://git.litislab.fr/tdemare/DALSim/wikis/home](https://git.litislab.fr/tdemare/DALSim/wikis/home)

# Install

## Stable version

In order to execute the simulation of this model, you need a special build of the [GAMA Platform](https://gama-platform.github.io/) which includes the plugins developed in parallel of this work.

You can find the release of the GAMA Platform here (and choose the last one):

[https://git.litislab.fr/tdemare/DALSim/tags/](https://git.litislab.fr/tdemare/DALSim/tags/)

Once you started the platform, you just need to import this repository as a project. 

Then, you can execute a simulation !

If you need to use the developer version, you must follow these instructions:

## Developper version

The first step consists to instal the "Git" version of GAMA following this tutorial:

- https://github.com/gama-platform/gama/wiki/InstallingGitVersion

Then, you need to download the following repositories and to import them into Eclipse as projects:

- https://github.com/graphstream/gs-gama
- https://git.litislab.fr/tdemare/TransportOrganizerPlugin
- https://git.litislab.fr/tdemare/MovingOnNetworkPlugin
- https://git.litislab.fr/tdemare/AnalyseNetworkPlugin

These four plugins are configured to work with the Graphstream library (version 1.3). So you need to add the library to these plugins. To do so, download "gs-core" and gs-algo" here:

- https://data.graphstream-project.org/pub/1.x/nightly-build/last/gs-algo-1.3-SNAPSHOT-last.jar
- https://data.graphstream-project.org/pub/1.x/nightly-build/last/gs-core-1.3-SNAPSHOT-last.jar

Then, in Eclipse, for each plugin, do a right click on a project (the project containing the source code and not the feature), then go in properties > Java Build Path > Libraries > Add External Jars > select both gs-core and gs-algo  > Apply and Close.

After that, you need to include the plugins to GAMA following the section Addition of a feature to the product" of this tutorial:

- https://github.com/gama-platform/gama/wiki/DevelopingPlugins

At this point, you are able to start GAMA (according to the method described here: https://github.com/gama-platform/gama/wiki/InstallingGitVersion) which will ask you to choose a workspace. Once started, you can import to your workspace the GAMA model of this current repository.
