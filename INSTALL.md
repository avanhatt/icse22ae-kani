# Installation 

Our artifact is set to run entirely within an interactive Docker instance. 

First, install Docker using the instructions for your host system as described [here][docker].

Then, run an interactive Docker session with:

```
docker run -v <path-to-artifact>:/icse22ae-kani -it icse22ae-kani:latest 
```

Where <path-to-artifact> is the root directory of this file.

To exit the Docker session, run `ctrl+d`.