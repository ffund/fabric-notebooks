::: {.cell .markdown}


##  Adaptive video

This experiment explores the tradeoff between different metrics of video quality (average rate, interruptions, and variability of rate) in an adaptive video delivery system.

This experiment runs on FABRIC. You will need an account on FABRIC, and you will need to have set up bastion keys, and a FABRIC configuration to run it.

It should take about 60-120 minutes to run this experiment.

:::


::: {.cell .markdown}

## Background

**Note:** Parts of this section are reproduced from [a blog post on adaptive video](https://witestlab.poly.edu/blog/adaptive-video/).


:::

::: {.cell .markdown}


### Adaptive video


:::

::: {.cell .markdown}

In general high-quality video requires a higher data rate than a lower-quality equivalent. Consider the following two video frames. The first shows a video encoded at 200kbps:

![](https://witestlab.poly.edu/blog/content/images/2016/02/dash-200.png)

Here's the same frame at 500kbps, with noticeably better quality:

![](https://witestlab.poly.edu/blog/content/images/2016/02/dash-500.png)


:::

::: {.cell .markdown}


For web services that want to share video with their users, this poses a dilemma - what quality level should they use to encode the video? If a video is low quality, it will stream without interruption even on a slow 3G cellular connection, but a user on a high speed fiber network may be unhappy with the video quality. Or, the video may be high quality, but then the slow connection would not be able to stream it without constant interruptions.

Fortunately, there is a solution to this dilemma: adaptive video. Instead of delivering exactly the same video to every user, adaptive video delivers video that is matched to the individual user's network quality.

There are many different adaptive video products: Microsoft Smooth Streaming, Apple HTTP Live Streaming (HLS), Adobe HTTP Dynamic Streaming (HDS), and Dynamic Adaptive Streaming over HTTP (DASH). This experiment focuses on DASH, which is widely supported as an international standard. 



:::

::: {.cell .markdown}


To prepare a video for adaptive video streaming with DASH, the video file is first encoded into different versions, each having a different rate and/or resolution. These are called *representations* or media presentations. The representations of a video all have the same content, but they differ in quality.

Each of these is further subdivided in time into *segments* of equal lengths (e.g., four seconds).

![](https://witestlab.poly.edu/blog/content/images/2016/02/dash-stored.png)

The content server then stores all of the segments of all of the representations (as separate files). Alongside these files, the content server stores a manifest file, called the Media Presentation Description (MPD). This is an XML file that identifies the various representations, identifies the video resolution and playback rate for each, and gives the location of every segment in each representation.

With these preparations complete, a user can begin to stream adaptive video from the server!


:::

::: {.cell .markdown}

Once the MPD and video files are in place, users can start requesting DASH video.

First, the user requests the MPD file. It parses the MPD file, learns what representations are available, and decides what representation to request for the first segment. It then retrieves that specific file using the URL given in the MPD.

The user's device keeps a video buffer (at the application layer). As new segments are retrieved, they are placed in the buffer. As video is played back, it is removed from the buffer. 

Each time a client finishes retrieving a file into the buffer, it makes a new decision as to what representation to get for the next segment.


For example, the client might request the following representations for the first four segments of video:

![](https://witestlab.poly.edu/blog/content/images/2016/02/dash-requested.png)

The cumulative set of decisions made by the client is called a decision policy. The decision policy is a set of rules that determine which representation to request, based on some kind of client state - for example, what the current download rate is, or how much video is currently stored in the buffer.

The decision policy is not specified in the DASH standard. Many decision policies have been proposed by researchers, each promising to deliver better quality than the next!


:::

::: {.cell .markdown}

### DASH decision policies


:::

::: {.cell .markdown}

The obvious policy to maximize video quality alone would be to always retrive segments at the highest quality level. However, with this policy the user is likely to experience rebuffering - when playback is interrupted and the user has to wait for more video to be downloaded. This occurs when the video is being played back (and therefore, removed from the buffer) faster than it is being retrieved - i.e., the playback rate is higher than the download rate - so the buffer becomes empty. This state, which is known as buffer starvation, is obviously something we wish very much to avoid.


To create a positive user experience for streaming video, therefore, requires a delicate balancing act.

* On the one hand, increasing the video playback rate too much (so that it is higher than the download rate) causes the undesired rebuffers.
* On the other hand, decreasing the video playback rate also decreases the user-perceived video quality.


Performing rate selection to balance rebuffer avoidance and quality optimization is an ongoing tradeoff. Different DASH policies may make different decisions about how to balance that tradeoff. Different DASH policies may also decide to use different pieces of information for decision making. For example:
 
* A decision policy may decide to focus on download rate in its decision making - select the quality level for the next video segment according to the download rate from the previous segment(s).
* Or, a decision policy may focus on buffer occupancy (how much video is already downloaded into the buffer, waiting to be played back?) If there is already a lot of video in the buffer, the decision policy can afford to be aggressive in its quality selection, since it has a cushion to protect it from rebuffering. On the other hand, if there is not much video in the buffer, the decision policy should be careful not to select a quality level that is too optimistic, since it is at high risk of rebuffering.


:::

::: {.cell .markdown}

### Specific policies in this implementation


:::

::: {.cell .markdown}


In this experiment, we will use the DASH implementation developed for the following paper:

> P. Juluri, V. Tamarapalli and D. Medhi, "SARA: Segment aware rate adaptation algorithm for dynamic adaptive streaming over HTTP," 2015 IEEE International Conference on Communication Workshop (ICCW), 2015, pp. 1765-1770, doi: 10.1109/ICCW.2015.7247436.

which is available on [Github](https://github.com/pari685/AStream). It includes three DASH decision policies:

The "basic" policy selects the video rate that is one level lower than the current network data rate. You can see [the "basic" implementation here](https://github.com/pari685/AStream/blob/master/dist/client/adaptation/basic_dash2.py).

The buffer-based rate adaptation ("Netflix") algorithm uses the estimated network data rate only during the initial startup phase. Otherwise, it makes quality decisions based on the buffer occupancy. It is based on the algorithm described in the following paper:

> Te-Yuan Huang, Ramesh Johari, Nick McKeown, Matthew Trunnell, and Mark Watson. 2014. A buffer-based approach to rate adaptation: evidence from a large video streaming service. In Proceedings of the 2014 ACM conference on SIGCOMM (SIGCOMM '14). Association for Computing Machinery, New York, NY, USA, 187–198. DOI:https://doi.org/10.1145/2619239.2626296

You can see [the "Netflix" implementation here](https://github.com/pari685/AStream/blob/master/dist/client/adaptation/netflix_dash.py). 

Finally, the segment-aware rate adaptation ("SARA") algorithm uses the actual size of the segment and data rate of the network to estimate the time it would take to download the next segment. Then, given the current buffer occupancy, it selects the best possible video quality while avoiding buffer starvation. It is described in 

> P. Juluri, V. Tamarapalli and D. Medhi, "SARA: Segment aware rate adaptation algorithm for dynamic adaptive streaming over HTTP," 2015 IEEE International Conference on Communication Workshop (ICCW), 2015, pp. 1765-1770, doi: 10.1109/ICCW.2015.7247436.

You can see [the "SARA" implementation here](https://github.com/pari685/AStream/blob/master/dist/client/adaptation/weighted_dash.py).


:::

::: {.cell .markdown}

## Run my experiment

:::

::: {.cell .markdown}

### Set up FABRIC configuration

In the next step, we will load a personal FABRIC configuration before attempting to reserve resources. 

:::


::: {.cell .code}

```python
from fabrictestbed_extensions.fablib.fablib import FablibManager as fablib_manager
fablib = fablib_manager()
fablib.show_config()

# set appropriate permission on your keys
!chmod 600 {fablib.get_bastion_key_filename()}
!chmod 600 {fablib.get_default_slice_private_key_file()}
```
:::


::: {.cell .markdown}

### Reserve resources


:::


::: {.cell .markdown}

Give your slice a unique name. You can also set the FABRIC site at which you want to reserve resources in the cell below:

:::


::: {.cell .markdown}

Now we are ready to reserve resources.
:::

::: {.cell .markdown}


If you already have the resources for this experiment (for example: you ran this part of the notebook previously, and are now returning to pick off where you left off), you don't need to reserve resources again. If the following cell tells you that you already have resources, you can just skip to the part where you left off last.


:::


::: {.cell .code}
```python
import json
import traceback
import os

SLICENAME="adaptive-video_" + os.getenv('NB_USER')


try:
    slice = fablib.get_slice(SLICENAME)
    print("You already have a slice named %s." % SLICENAME)
    print(slice)
except:
    slice = fablib.new_slice(name=SLICENAME)
    print("You will need to create a %s slice." % SLICENAME)
```
:::


::: {.cell .markdown}

Next, we’ll select a random FABRIC site for our experiment. We’ll make sure to get one that has sufficient capacity for the experiment we’re going to run.

Once we find a suitable site, we’ll print details about available resources at this site.

:::


::: {.cell .code}
```python
exp_requires = {'core': 4*3, 'nic': 4}
while True:
    site_name = fablib.get_random_site()
    if ( (fablib.resources.get_core_available(site_name) > 1.2*exp_requires['core']) and
        (fablib.resources.get_component_available(site_name, 'SharedNIC-ConnectX-6') > 1.2**exp_requires['nic']) ):
        break

fablib.show_site(site_name)
```
:::


::: {.cell .markdown}


Then, set up your resource request and then submit it to FABRIC:

:::

::: {.cell .code}
```python
# this cell sets up hosts and routers
node_names = ["romeo", "router", "juliet"]
for n in node_names:
    slice.add_node(name=n, site=site_name, cores=4, image='default_ubuntu_20')
```
:::


::: {.cell .code}
```python
# this cell sets up the network links
nets = [
    {"name": "net0",   "nodes": ["romeo", "router"]},
    {"name": "net1",  "nodes": ["router", "juliet"]}
]
for n in nets:
    ifaces = [slice.get_node(node).add_component(model="NIC_Basic", name=n["name"]).get_interfaces()[0] for node in n['nodes'] ]
    slice.add_l2network(name=n["name"], type='L2Bridge', interfaces=ifaces)
```
:::



::: {.cell .markdown}
The following cell submits our request to the FABRIC site. The output of this cell will update automatically as the status of our request changes. 

* While it is being prepared, the "State" of the slice will appear as "Configuring". 
* When it is ready, the "State" of the slice will change to "StableOK".
:::



::: {.cell .code}
```python
slice.submit()
```
:::


::: {.cell .markdown}
Even after the slice is fully configured, it may not be immediately ready for us to log in. The following cell will return when the hosts in the slice are ready for us to use.
:::


::: {.cell .code}
```python
slice.wait_ssh(progress=True)
```
:::



::: {.cell .markdown}

Then we can get login details for every node:

:::


::: {.cell .code}

```python
for node in slice.get_nodes():
    print(f"{node}")
```
:::



::: {.cell .markdown}

In the rest of this notebook, we'll execute commands on these nodes by accessing them over SSH. We'll define some variables with the login details and NIC names for the three nodes to assist with this:

:::


::: {.cell .code}

```python
# variables specific to this slice
ROMEO_IP = str(slice.get_node("romeo").get_management_ip())
ROMEO_USER =  str(slice.get_node("romeo").get_username())
ROMEO_IFACE_R = slice.get_node("romeo").get_interfaces()[0].get_os_interface()

JULIET_IP = str(slice.get_node("juliet").get_management_ip())
JULIET_USER =  str(slice.get_node("juliet").get_username())
JULIET_IFACE_J = slice.get_node("juliet").get_interfaces()[0].get_os_interface()


ROUTER_IP = str(slice.get_node("router").get_management_ip())
ROUTER_USER =  str(slice.get_node("router").get_username())
ROUTER_IFACE_J = slice.get_node("router").get_component("net1").get_interfaces()[0].get_os_interface()
ROUTER_IFACE_R = slice.get_node("router").get_component("net0").get_interfaces()[0].get_os_interface()

FABRIC_SLICE_PRIVATE_KEY_FILE = fablib.get_default_slice_private_key_file
FABRIC_BASTION_USERNAME = fablib.get_bastion_username()
FABRIC_BASTION_HOST = fablib.get_bastion_public_addr()

SSH_CMD_ROMEO=slice.get_node('romeo').get_ssh_command()
SSH_CMD_JULIET=slice.get_node('juliet').get_ssh_command()
SSH_CMD_ROUTER=slice.get_node('router').get_ssh_command()
```
:::




::: {.cell .markdown}

### One-time setup


:::


::: {.cell .markdown}


### Set up network

Next, we need to configure our resources - assign IP addresses to network interfaces, enable forwarding on the router, and install any necessary software.

:::



::: {.cell .markdown}
First, we'll configure IP addresses:
:::


::: {.cell .code}
```python
from ipaddress import ip_address, IPv4Address, IPv4Network

if_conf = {
    "romeo-net0-p1":   {"addr": "192.168.0.2", "subnet": "192.168.0.0/24"},
    "router-net0-p1":  {"addr": "192.168.0.1", "subnet": "192.168.0.0/24"},
    "router-net1-p1":  {"addr": "192.168.1.1", "subnet": "192.168.1.0/24"},
    "juliet-net1-p1":  {"addr": "192.168.1.2", "subnet": "192.168.1.0/24"}
}

for iface in slice.get_interfaces():
    if_name = iface.get_name()
    iface.ip_addr_add(addr=if_conf[if_name]['addr'], subnet=IPv4Network(if_conf[if_name]['subnet']))
```
:::


::: {.cell .markdown}
Then, we'll add routes so that romeo knows how to reach juliet, and vice versa.
:::


::: {.cell .code}
```python
rt_conf = [
    {"name": "romeo",   "addr": "192.168.1.0/24", "gw": "192.168.0.1"},
    {"name": "juliet",  "addr": "192.168.0.0/24", "gw": "192.168.1.1"}
]
for rt in rt_conf:
    slice.get_node(name=rt['name']).ip_route_add(subnet=IPv4Network(rt['addr']), gateway=rt['gw'])
```
:::


::: {.cell .markdown}
And, we'll enable IP forwarding on the router:
:::


::: {.cell .code}
```python
for n in ['router']:
    slice.get_node(name=n).execute("sudo sysctl -w net.ipv4.ip_forward=1")
```
:::


::: {.cell .markdown}
Let's make sure that all of the network interfaces are brought up:
:::


::: {.cell .code}
```python
for iface in slice.get_interfaces():
    iface.ip_link_up()
```
:::



::: {.cell .markdown}

The following cell will make sure that the FABRIC nodes can reach targets on the Internet (e.g. to retrieve files or software), even if the FABRIC nodes connect to the Internet through IPv6 and the targetes on the Internet are IPv4 only, by using [nat64](https://nat64.net/).

:::


::: {.cell .code}
```python
for node in ["romeo", "juliet", "router"]:
    slice.get_node(node).execute("sudo sed -i '/nameserver/d' /etc/resolv.conf")
    slice.get_node(node).execute("echo nameserver 2a00:1098:2c::1 | sudo tee -a /etc/resolv.conf")
    slice.get_node(node).execute("echo nameserver 2a01:4f8:c2c:123f::1 | sudo tee -a /etc/resolv.conf")
    slice.get_node(node).execute("echo nameserver 2a00:1098:2b::1 | sudo tee -a /etc/resolv.conf")
    slice.get_node(node).execute('echo "127.0.0.1 $(hostname -s)" | sudo tee -a /etc/hosts')
```
:::



::: {.cell .markdown}
Finally, we'll install some software. 
:::


::: {.cell .code}
```python
for n in ['romeo', 'router', 'juliet']:
    slice.get_node(name=n).execute("sudo apt update; sudo apt -y install net-tools iperf3 moreutils", quiet=True)
```
:::



::: {.cell .markdown}
and, quiet the login banner so we don't have to see it each time we log in:

:::


::: {.cell .code}
```python
for n in ['romeo', 'router', 'juliet']:
    slice.get_node(name=n).execute("touch ~/.hushlogin", quiet=True)
```
:::


::: {.cell .markdown}


Now we can test our configuration! We will `ping` from romeo to juliet:

:::


::: {.cell .code}

```bash
%%bash -s "$SSH_CMD_ROMEO"
$1 << EOF
##############################################

ping -c 5 192.168.1.2

##############################################
exit
EOF
```

:::



::: {.cell .markdown}

### Set up for adaptive video experiment

:::

::: {.cell .markdown}


Next, we will set up juliet as an adaptive video "server". We will run this in the background, just so that we can continue to romeo in the meantime, but we need to make sure it's finished before we start the experiment.

:::


::: {.cell .code}


```bash
%%bash --bg -s "$SSH_CMD_JULIET"
$1 << EOF
##############################################

sudo apt install -y apache2  
wget https://nyu.box.com/shared/static/d6btpwf5lqmkqh53b52ynhmfthh2qtby.tgz -O media.tgz -o wget.log 
sudo tar -v -xzf media.tgz -C /var/www/html/  

##############################################
exit
EOF
```

:::

::: {.cell .markdown}


Set up romeo as an adaptive video "client".


:::


::: {.cell .code}

```bash
%%bash -s "$SSH_CMD_ROMEO"
$1 << EOF
##############################################

sudo apt install -y python2 ffmpeg

##############################################
exit
EOF
```

:::

::: {.cell .markdown}

In this experiment, we will use the DASH implementation developed for the following paper:

> P. Juluri, V. Tamarapalli and D. Medhi, "SARA: Segment aware rate adaptation algorithm for dynamic adaptive streaming over HTTP," 2015 IEEE International Conference on Communication Workshop (ICCW), 2015, pp. 1765-1770, doi: 10.1109/ICCW.2015.7247436.

which is available on [Github](https://github.com/pari685/AStream). It includes three DASH decision policies:

The "basic" policy selects the video rate that is one level lower than the current network data rate. You can see [the "basic" implementation here](https://github.com/pari685/AStream/blob/master/dist/client/adaptation/basic_dash2.py).

The buffer-based rate adaptation ("Netflix") algorithm uses the estimated network data rate only during the initial startup phase. Otherwise, it makes quality decisions based on the buffer occupancy. It is based on the algorithm described in the following paper:

> Te-Yuan Huang, Ramesh Johari, Nick McKeown, Matthew Trunnell, and Mark Watson. 2014. A buffer-based approach to rate adaptation: evidence from a large video streaming service. In Proceedings of the 2014 ACM conference on SIGCOMM (SIGCOMM '14). Association for Computing Machinery, New York, NY, USA, 187–198. DOI:https://doi.org/10.1145/2619239.2626296

You can see [the "Netflix" implementation here](https://github.com/pari685/AStream/blob/master/dist/client/adaptation/netflix_dash.py). 

Finally, the segment-aware rate adaptation ("SARA") algorithm uses the actual size of the segment and data rate of the network to estimate the time it would take to download the next segment. Then, given the current buffer occupancy, it selects the best possible video quality while avoiding buffer starvation. It is described in 

> P. Juluri, V. Tamarapalli and D. Medhi, "SARA: Segment aware rate adaptation algorithm for dynamic adaptive streaming over HTTP," 2015 IEEE International Conference on Communication Workshop (ICCW), 2015, pp. 1765-1770, doi: 10.1109/ICCW.2015.7247436.

You can see [the "SARA" implementation here](https://github.com/pari685/AStream/blob/master/dist/client/adaptation/weighted_dash.py).

We will retrieve this open-source implementation on romeo:


:::


::: {.cell .code}

```bash
%%bash -s "$SSH_CMD_ROMEO"
$1 << EOF
##############################################

git clone https://github.com/pari685/AStream  

##############################################
exit
EOF
```
:::

::: {.cell .markdown}

Make sure the video server is ready on juliet. The output should show the BigBuckBunny directories. A "No such file or directory" error message means that the setup process we left running in the background has not yet finished, and you should check again a little while later:

:::


::: {.cell .code}

```bash
%%bash -s "$SSH_CMD_JULIET"
$1 << EOF
##############################################

ls /var/www/html/media/BigBuckBunny/4sec

##############################################
exit
EOF
```
:::

::: {.cell .markdown}


The web server directory now contains 4-second segments of the "open" video clip [Big Buck Bunny](https://peach.blender.org/about/), encoded at different quality levels. The Big Buck Bunny DASH dataset is from:

> Stefan Lederer, Christopher Müller, and Christian Timmerer. 2012. Dynamic adaptive streaming over HTTP dataset. In Proceedings of the 3rd Multimedia Systems Conference (MMSys '12). Association for Computing Machinery, New York, NY, USA, 89–94. DOI:https://doi.org/10.1145/2155555.2155570



:::

::: {.cell .markdown}


### Execute experiment


:::

::: {.cell .markdown}

Now, we can try an experiment! We will retrieve the first 30 segments of the video, using the "netflix" policy. But we will also set the router data rate to be 1Mbps for 20 seconds, then 100Kbps for 20 seconds, and then back to 1Mbps.

:::


::: {.cell .code}


```bash
%%bash --bg -s "$SSH_CMD_ROUTER" "$ROUTER_IFACE_R" "$ROUTER_IFACE_J"
$1 << EOF
##############################################

sudo tc qdisc del dev $2 root  
sudo tc qdisc add dev $2 root handle 1: htb default 3  
sudo tc class add dev $2 parent 1: classid 1:3 htb rate 1Mbit  
sudo tc qdisc add dev $2 parent 1:3 handle 3: bfifo limit 0.1MB
sudo tc qdisc show dev $2
        
sudo tc qdisc del dev $3 root  
sudo tc qdisc add dev $3 root handle 1: htb default 3  
sudo tc class add dev $3 parent 1: classid 1:3 htb rate 1Mbit  
sudo tc qdisc add dev $3 parent 1:3 handle 3: bfifo limit 0.1MB  
sudo tc qdisc show dev $3

sleep 20

sudo tc qdisc del dev $2 root  
sudo tc qdisc add dev $2 root handle 1: htb default 3  
sudo tc class add dev $2 parent 1: classid 1:3 htb rate 100Kbit  
sudo tc qdisc add dev $2 parent 1:3 handle 3: bfifo limit 0.1MB
sudo tc qdisc show dev $2
        
sudo tc qdisc del dev $3 root  
sudo tc qdisc add dev $3 root handle 1: htb default 3  
sudo tc class add dev $3 parent 1: classid 1:3 htb rate 100Kbit  
sudo tc qdisc add dev $3 parent 1:3 handle 3: bfifo limit 0.1MB  
sudo tc qdisc show dev $3

sleep 20


sudo tc qdisc del dev $2 root  
sudo tc qdisc add dev $2 root handle 1: htb default 3  
sudo tc class add dev $2 parent 1: classid 1:3 htb rate 1Mbit  
sudo tc qdisc add dev $2 parent 1:3 handle 3: bfifo limit 0.1MB
sudo tc qdisc show dev $2
        
sudo tc qdisc del dev $3 root  
sudo tc qdisc add dev $3 root handle 1: htb default 3  
sudo tc class add dev $3 parent 1: classid 1:3 htb rate 1Mbit  
sudo tc qdisc add dev $3 parent 1:3 handle 3: bfifo limit 0.1MB  
sudo tc qdisc show dev $3

##############################################
exit
EOF
```

:::


::: {.cell .code}

```bash
%%bash -s "$SSH_CMD_ROMEO"
$1 << EOF
##############################################

python2 ~/AStream/dist/client/dash_client.py -m http://192.168.1.2/media/BigBuckBunny/4sec/BigBuckBunny_4s.mpd -p 'netflix' -n 30 -d

##############################################
exit
EOF
```

:::

::: {.cell .markdown}

The log files will be inside `ASTREAM_LOGS`, and the video files will be inside a directory beginning with `TEMP_`. We will get the directory/file names from this next command, and use it to modify the following cells.

:::


::: {.cell .code}


```bash
%%bash -s "$SSH_CMD_ROMEO"
$1 << EOF
##############################################

ls -alstr ~/
ls -alstr ~/ASTREAM_LOGS

##############################################
exit
EOF
```

:::


::: {.cell .markdown}


### Data analysis


:::

::: {.cell .markdown}

We can recreate the video from the segments, which are stored in the `TEMP_` directory.

:::


::: {.cell .code}

```bash
%%bash -s "$SSH_CMD_ROMEO"
$1 << EOF
##############################################

cd ~/TEMP_MBvypN
rm -f BigBuckBunny.mp4 # if it exists
cat BigBuckBunny_4s_init.mp4 \$(ls -vx BigBuckBunny_*.m4s) > BigBuckBunny_tmp.mp4
ffmpeg -i  BigBuckBunny_tmp.mp4 -c copy BigBuckBunny.mp4

mv BigBuckBunny.mp4 ~/

##############################################
exit
EOF
```

:::


::: {.cell .code}

```python
slice.get_node("romeo").download_file("/home/fabric/work/BigBuckBunny.mp4", "/home/ubuntu/BigBuckBunny.mp4")
```

:::


::: {.cell .code}


```python
from IPython.display import Video

Video("/home/fabric/work/BigBuckBunny.mp4", embed=True)
```

:::

::: {.cell .markdown}

We can also retrieve the adaptive video log data.

:::


::: {.cell .code}


```python
slice.get_node("romeo").download_file("/home/fabric/work/DASH_BUFFER_LOG.csv", "/home/ubuntu/ASTREAM_LOGS/DASH_BUFFER_LOG_2022-04-14.14_55_27.csv")
```
:::

::: {.cell .markdown}

and do some data analysis:

:::


::: {.cell .code}

```python
import matplotlib.pyplot as plt
import pandas as pd

c = {'INITIAL_BUFFERING': 'violet', 'PLAY': 'lightcyan', 'BUFFERING': 'lightpink'}

dash = pd.read_csv("/home/fabric/work/DASH_BUFFER_LOG.csv")
dash = dash.loc[dash.CurrentPlaybackState.isin(c.keys() )]
states = pd.DataFrame({'startState': dash.CurrentPlaybackState[0:-2].values, 'startTime': dash.EpochTime[0:-2].values,
                        'endState':  dash.CurrentPlaybackState[1:-1].values, 'endTime':   dash.EpochTime[1:-1].values})


for index, s in states.iterrows():
  plt.axvspan(s['startTime'], s['endTime'],  color=c[s['startState']], alpha=1) 

plt.plot(dash[dash.Action!="Writing"].EpochTime, dash[dash.Action!="Writing"].Bitrate, 'kx:')
plt.title("Video rate (bps)");
plt.xlabel("Time (s)");
```
:::


::: {.cell .markdown}


## Delete slice

:::

::: {.cell .markdown}


When you are finished, delete your slice to free resources for other experimenters.


:::


::: {.cell .code}

```python
fablib.delete_slice(SLICENAME)
```

:::
