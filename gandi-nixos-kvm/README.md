This directory serves only as historical documentation of an experiment on
Gandi.net (https://www.gandi.net/en-US).

The intention was to find a very inexpensive KVM provider. (They offered
GandiCloud VPS, with 8G RAM, 25G storage, etc., for $38/month. About $46 for
~250G storage.) This did not work well because of the way that a "reboot" on
that platform caused the booting process not to actually boot the disk as
configured. Also, it was slow. A DigitalOcean droplet ($48/month) would likely
give a better experience. VPS2Day is an experiment that yielded better results.

Nonetheless, I preserve the configuration of that NixOS host/container for
posterity.
