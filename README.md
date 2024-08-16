# patriceckhart/timemachine

Docker image to run Samba (netatalk) to provide a compatible Time Machine for MacOS

## Example usage for Samba

Example usage with `--net=host` to allow Avahi discovery; with commonly used environment variables set to their default values:

```
docker run -d --restart=always \
  --name timemachine \
  --net=host \
  -e TM_USERNAME="timemachine" \
  -e TM_GROUPNAME="timemachine" \
  -e PASSWORD="timemachine" \
  -e TM_UID="1000" \
  -e TM_GID="1000" \
  -e SET_PERMISSIONS="false" \
  -e VOLUME_SIZE_LIMIT="0" \
  -v /path/on/host/to/backup/to/for/timemachine:/opt/timemachine \
  --tmpfs /run/samba \
  patriceckhart/timemachine:smb
```

Example usage with exposing ports _without_ Avahi discovery; with commonly used environment variables set to their default values:

```
docker run -d --restart=always \
  --name timemachine \
  --hostname timemachine \
  -p 137:137/udp \
  -p 138:138/udp \
  -p 139:139 \
  -p 445:445 \
  -e TM_USERNAME="timemachine" \
  -e TM_GROUPNAME="timemachine" \
  -e PASSWORD="timemachine" \
  -e TM_UID="1000" \
  -e TM_GID="1000" \
  -e SET_PERMISSIONS="false" \
  -e VOLUME_SIZE_LIMIT="0" \
  -v /path/on/host/to/backup/to/for/timemachine:/opt/timemachine \
  --tmpfs /run/samba \
  patriceckhart/timemachine:smb
```

### Tips for Automatic Discovery w/Avahi

This works best with `--net=host` so that discovery can be broadcast. Otherwise, you will need to expose the above ports and then you must manually map the share in Finder for it to show up (open `Finder`, click `Shared`, and connect as `smb://hostname-or-ip/TimeMachine` with your TimeMachine credentials).  Using `--net=host` only works if you do not already run Samba or Avahi on the host!  Alternatively, you can use the `SMB_PORT` option to change the port that Samba uses.  See below for another workaround if you do not wish to change the Samba port.

#### Volume & File system Permissions

If you're using an external volume like in the example above, you will need to set the filesystem permissions on disk.  By default, the `timemachine` user is `1000:1000`.

The backing data store for your persistent time machine data _must_ support extended file attributes (`xattr`).  Remote file systems, such as NFS, will very likely not support `xattr`s.  See [#61](https://github.com/mbentley/docker-timemachine/issues/61) for more details.  This image will check and try to set `xattr`s to a test file in `/opt/${TM_USERNAME}` to warn the user if they are not supported but this will not prevent the image from running.

#### Persistent Data Path

If you change the `TM_USERNAME` value, it will change the persistent data path from `/opt/timemachine` to `/opt/<value-of-TM_USERNAME>`. Failure to map this appropriately will lead to data being stored inside the container and not in the volume you have specified!

#### Default credentials

* Username: `timemachine`
* Password: `timemachine`

### Optional variables for SMB

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `ADVERTISED_HOSTNAME` | _not set_ | Avahi will advertise the smb services at this hostname instead of the local hostname (useful in Docker without `--net=host`). **Do not set this if you don't know what you're doing!** |
| `CUSTOM_SMB_AUTH` | `no` | set to yes, indicates that you want Samba to attempt to authenticate users using the [NTLM Encrypted Password Response](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#idm7319) |
| `CUSTOM_SMB_CONF` | `false` | indicates that you are going to bind mount a custom config to `/etc/samba/smb.conf` if set to `true` |
| `CUSTOM_SMB_PROTO` | `SMB2` | indicates that you want to allow another value from [Samba Protocol List](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#CLIENTMAXPROTOCOL) |
| `CUSTOM_USER` | `false` | indicates that you are going to bind mount `/etc/password`, `/etc/group`, and `/etc/shadow`; and create data directories if set to `true` |
| `DEBUG_LEVEL` | `1` | sets the debug level for `nmbd` and `smbd` |
| `EXTERNAL_CONF` | _not set_ | specifies a directory in which individual variable files, ending in `.conf`, for multiple users; see [Adding Multiple Users & Shares](#adding-multiple-users--shares) for more info |
| `HIDE_SHARES` | `no` | set to `yes` if you would like only the share(s) a user can access to appear |
| `MIMIC_MODEL` | `TimeCapsule8,119` | sets the value of time machine to mimic |
| `TM_USERNAME` | `timemachine` | sets the username time machine runs as |
| `TM_GROUPNAME` | `timemachine` | sets the group name time machine runs as |
| `TM_UID` | `1000` | sets the UID of the `TM_USERNAME` user |
| `TM_GID` | `1000` | sets the GID of the `TM_GROUPNAME` group |
| `PASSWORD` | `timemachine` | sets the password for the `timemachine` user |
| `SET_PERMISSIONS` | `false` | set to `true` to have the entrypoint set ownership and permission on the `/opt/<username>` in the container |
| `SHARE_NAME` | `TimeMachine` | sets the name of the timemachine share to TimeMachine by default |
| `SMB_INHERIT_PERMISSIONS` | `no` | if yes, permissions for new files will be forced to match the parent folder |
| `SMB_NFS_ACES` | `no` | value of `fruit:nfs_aces`; support for querying and modifying the UNIX mode of directory entries via NFS ACEs |
| `SMB_METADATA` | `stream` | value of `fruit:metadata`; controls where the OS X metadata stream is stored |
| `SMB_PORT` | `445` | sets the port that Samba will be available on |
| `SMB_VFS_OBJECTS` | `fruit streams_xattr` | value of `vfs objects` |
| `VOLUME_SIZE_LIMIT` | `0` | sets the maximum size of the time machine backup; a unit can also be passed (e.g. - `1 T`). See the [Samba docs](https://www.samba.org/samba/docs/current/man-html/vfs_fruit.8.html) under the `fruit:time machine max size` section for more details |
| `WORKGROUP` | `WORKGROUP` | set the Samba workgroup name |
| `IGNORE_DOS_ATTRIBUTES` | `false` | If set to `true` Samba will ignore DOS attributes. This is accomplished by setting [store dos attributes](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#STOREDOSATTRIBUTES), [map hidden](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#MAPHIDDEN), [map system](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#MAPSYSTEM), [map archive](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#MAPARCHIVE) and [map readonly](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#MAPREADONLY) to `no` in the `[global]` section. |

### Adding Multiple Users & Shares

In order to add multiple users who have their own shares, you will need to create a file for each user and put them in a directory. The file name __must__ end in `.conf` or it will not be parsed and the contents must be environment variable formatted proper and include all of the values below in the example.  Only `VOLUME_SIZE_LIMIT` can be empty if you do not want to set a quota.
