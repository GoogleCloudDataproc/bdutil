Deploying Hama on Google Compute Engine
===============================================

Apache Hama
-----------
Apache Hama is a framework for Big Data analytics which uses the Bulk Synchronous Parallel (BSP) computing model, which was established in 2012 as a Top-Level Project of The Apache Software Foundation. 

It provides not only pure BSP programming model but also vertex and neuron centric programming models, inspired by Google's Pregel and DistBelief.

Basic Usage
-----------

Basic installation of [Apache Hama](http://hama.apache.org/) alongside Hadoop on Google Cloud Platform.

    ./bdutil -e extensions/hama/hama_env.sh deploy

Or alternatively, using shorthand syntax:

    ./bdutil -e hama deploy

Status
------

This plugin is currently considered experimental and not officially supported.
Contributions are welcome.
