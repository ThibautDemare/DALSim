Source code of the DALSim (Dynamic Graphs and Agents for Logistics Simulations)

HOW TO USE IT
-------------

In order to execute the simulation of this model, you need a special build of the GAMA Platform which includes the plugins developed in parallel of this work.

You can find the release of the GAMA Platform here:

https://git.litislab.fr/tdemare/DALSim/tags/v1.0

Once you started the platform, you just need to import this repository as a project. 

Then, you can execute a simulation !

If you need to use the developer version, you must follow these instructions:

INSTALL
-------

To use this model, you first nedd to install the GAMA platform and the plugins developped as part of this project.

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

INSTALLATION
------------

Pour utiliser ce modèle, vous devez d'abords avoir installé la plateforme GAMA avec les plugins développés dans le cadre de ce projet.

La première étape consiste à installer la version "Git" de GAMA en suivant ce guide :
- https://github.com/gama-platform/gama/wiki/InstallingGitVersion

Ensuite, il vous faudra rapatrier les différents plugins ci-dessous en les important comme projet à Eclipse :
- https://github.com/graphstream/gs-gama
- https://git.litislab.fr/tdemare/TransportOrganizerPlugin
- https://git.litislab.fr/tdemare/MovingOnNetworkPlugin
- https://git.litislab.fr/tdemare/AnalyseNetworkPlugin

Ces quatre plugins sont configurés pour fonctionner avec la librairie Graphstream (version 1.3). Vous devrez donc ajouter cette librairie. Pour cela, télécharger "gs-core" et "gs-algo" à ces deux adresses :
- https://data.graphstream-project.org/pub/1.x/nightly-build/last/gs-algo-1.3-SNAPSHOT-last.jar
- https://data.graphstream-project.org/pub/1.x/nightly-build/last/gs-core-1.3-SNAPSHOT-last.jar

Ensuite, dans Eclipse, pour chaque plugin, faites un clic droit sur le projet (le projet contenant les sources et non la feature), aller dans properties > Java Build Path > Libraries > Add External Jars > Sélectionner les deux fichiers téléchargés > Apply and Close.

Puis, pour chaque plugin, vous devrez les inclure à GAMA en suivant la section "Addition of a feature to the product" de ce tutoriel :
- https://github.com/gama-platform/gama/wiki/DevelopingPlugins

À partir de ce point vous pouvez lancer GAMA (selon la méthode décrite ici https://github.com/gama-platform/gama/wiki/InstallingGitVersion) qui vous demandera de choisir un workspace. Une fois lancé, vous pouvez importer à votre workspace le modèle GAMA de ce projet.