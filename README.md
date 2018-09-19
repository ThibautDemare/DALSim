Source code of the DALSim (Dynamic Graphs and Agents for Logistics Simulations)


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

Ces trois plugins sont configurés pour fonctionner avec la librairie Graphstream (version 1.3). Vous devrez donc ajouter cette librairie. Pour cela, télécharger "gs-core" et "gs-algo" à ces deux adresses :
- https://data.graphstream-project.org/pub/1.x/nightly-build/last/gs-algo-1.3-SNAPSHOT-last.jar
- https://data.graphstream-project.org/pub/1.x/nightly-build/last/gs-core-1.3-SNAPSHOT-last.jar

Ensuite, dans Eclipse, pour chaque plugin, faites un clic droit sur le projet (le projet contenant les sources et non la feature), aller dans properties > Java Build Path > Libraries > Add External Jars > Sélectionner les deux fichiers téléchargés > Apply and Close.

Puis, pour chaque plugin, vous devrez les inclure à GAMA en suivant la section "Addition of a feature to the product" de ce tutoriel :
- https://github.com/gama-platform/gama/wiki/DevelopingPlugins

À partir de ce point vous pouvez lancer GAMA (selon la méthode décrite ici https://github.com/gama-platform/gama/wiki/InstallingGitVersion) qui vous demandera de choisir un workspace. Une fois lancé, vous pouvez importer à votre workspace le modèle GAMA de ce projet.