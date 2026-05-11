# mailman2-python3-freebsd-port

FreeBSD port for [mailman2-python3](https://github.com/thegushi/mailman2-python3),
a Python 3 port of Mailman 2.1.39.  Intended as a drop-in replacement for
`mail/mailman` in the FreeBSD ports tree.

## Installation via ports overlay

Do **not** clone this into `/usr/ports/mail/mailman` — that stomps the existing
port.  Use a ports overlay instead so your local tree stays clean:

```sh
# Create an overlay directory (once)
mkdir -p /usr/local/poudriere/ports/overlay/mail/mailman

# Clone this repo into it
git clone git@github.com:thegushi/mailman2-python3-freebsd-port.git \
    /usr/local/poudriere/ports/overlay/mail/mailman

# Tell the ports framework to prefer the overlay
# Add to /etc/make.conf (or /usr/local/etc/poudriere.conf for poudriere):
OVERLAYS=/usr/local/poudriere/ports/overlay
```

From then on, `cd /usr/local/poudriere/ports/overlay/mail/mailman && git pull`
picks up updates without touching the main ports tree.

### Without poudriere

The same overlay mechanism works for a plain `make install` workflow:

```sh
mkdir -p /usr/local/ports-overlay/mail/mailman
git clone git@github.com:thegushi/mailman2-python3-freebsd-port.git \
    /usr/local/ports-overlay/mail/mailman
echo 'OVERLAYS=/usr/local/ports-overlay' >> /etc/make.conf
```

Then build as normal:

```sh
cd /usr/ports/mail/mailman   # the framework resolves to the overlay
make install clean
```

## Before building

Two things are needed that cannot be committed to this repo:

1. **`files/powerlogo.png`** — copy from the existing port:
   ```sh
   cp /usr/ports/mail/mailman/files/powerlogo.png \
       /path/to/overlay/mail/mailman/files/
   ```

2. **`distinfo`** — pin `GH_TAGNAME` in `Makefile` to a specific commit hash
   or release tag, then regenerate:
   ```sh
   make makesum
   ```

## Differences from mail/mailman (2.1.39_4)

| | mail/mailman | this port |
|---|---|---|
| Python | 2.7 | 3.9+ |
| dnspython dep | py-dnspython1 | py-dnspython |
| htdig option | yes | dropped (not Py3 compatible) |
| namazu2 option | yes | dropped (not Py3 compatible) |
| .pyc files | installed alongside .py | in `__pycache__/` (not tracked) |
