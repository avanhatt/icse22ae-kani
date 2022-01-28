# Installation 

Our artifact is set to run entirely within an interactive Docker instance. 

First, install Docker using the instructions for your host system as described [here][docker].

Then, run an interactive Docker session with:

```
docker run -i -t --rm ghcr.io/avanhatt/icse22ae-kani:0.0
```

To exit the Docker session, run `ctrl+d`.