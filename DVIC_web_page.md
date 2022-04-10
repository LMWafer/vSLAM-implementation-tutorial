**Simultaneous Localization And Mapping** (SLAM) consists of estimating an agent's location while mapping its environment. vSLAM - the visual branch of SLAM - involves cameras to track features over images and create a map of these. **Visual Odometry** (VO) - that is vSLAM "ancestor" - relies on point matching between pairs of frames to perform dead-reckoning. VO becamed famous in the early 2000's[^1]. vSLAM arrived few years later[^2] [^3]and brought points registration within a map. State-of-the-art algorithms now compute fast and robust ego-motion estimation & environment mapping with no prior knowledge of the scene structure nor agent's state : Ultimate SLAM[^4], MIT's Kimera[^5], BASALT[^6], DSM[^7]... ORB-SLAM[^8] library introduced a monocular vSLAM in 2015 based on ORB features extraction technic[^11]. ORB-SLAM2[^9] (2017) - its evolution - added RGB-D camera compatibility. ORB-SLAM3[^10] arrived in 2021 with inertial and multimap capabilities[^12].

# Introduction 

This tutorial is divided into difficulty levels. The higher the level, the more abstract your program becomes... and the closer to a robot you are !

## Why should I read this tutorial ? 

### for vSLAM understanding

Each step comes with an use-case point of view. Final objectives - that are vSLAM applications - are kept in mind through the whole tutorial to justify global choices. 

### for skills

This tutorial is made with concerns for novice people : all actions are explained in a "programming project" manner to bring versatile skills. Only vSLAM is implemented here, but you will learn more than vSLAM. 

## Skills & opportunity

@[split](2, begin)

### Required skills

This tutorial assumes basic filesystem navigation Linux commands are known. 

### Skills learned with Level 0

This level will introduce basis for dependencies installation:
- Package downloading
- Git repositories
- C++ library building with CMake

@[split](2, break)

### Skills learned with Level 1

Here you will learn general C++ program notions, through creation of a simple off-line vSLAM application:
- Basic vSLAM program structure
- Video's frames retrieval process
- C++ application building with CMake
- Executable running with Linux

@[split](2, begin)

### Skills learned with Level 2

This level shows how to develop a user-friendly and real-time vSLAM program:
- Python <--> C++ bindings
- Threading and callback
- Context managers
- Trajectory visualization

@[split](2, break)
### Skills learned with Level 3

Finally, you will discover how to make your vSLAM program safier and more portable thanks to containerization:
- Docker image building

@[split](2, end)


# Level 0 - Setup development environment with *Linux*
First, we need to install what will help us to create applications : ORB-SLAM3 and its dependencies. At the end of this level we will have a fully setup development environment. ORB-SLAM3 library and dependencies informations are available on [Zaragoza University SLAMlab's Github](https://github.com/UZ-SLAMLab/ORB_SLAM3). 

## Overview
@[split](2, begin)

Creating an ORB-SLAM3 based application requires Ubuntu 16.04 or 18.04 and several dependencies. Below is the list of perequisites. 
|      Name     | Version |               Usage              |       Installation mode      |
|:-------------:|:-------:|:--------------------------------:|:------------------------:|
|    Pangolin   |   last  | Visualization and user interface |    [*Built from source*](https://github.com/stevenlovegrove/Pangolin.git)   |
|     OpenCV[^13]    |   last  | Images and features manipulation |    [*Built from source*](https://github.com/Itseez/opencv.git)   |
|     Eigen3    |   last  |        Matrix manipulation       |         [*As Package*](https://neuro.debian.net/pkgs/libeigen3-dev.html)        |
|      g2o[^14]      |*modified*|      Map graph optimization      | [*Built from mod. source*](https://github.com/UZ-SLAMLab/ORB_SLAM3.git) |
|     Sophus    |*modified*|           3D operations          | [*Built from mod. source*](https://github.com/UZ-SLAMLab/ORB_SLAM3.git) |
|     DBoW2[^15]     |*modified*|          Relocalization          | [*Built from mod. source*](https://github.com/UZ-SLAMLab/ORB_SLAM3.git) |
| Realsense SDK |  2.5.0  |           Camera driver          |    [*Built from source*](https://github.com/IntelRealSense/librealsense.git)   |

@[split](2, break)

*Built from source* : download source code from Github, build library and install it.

*As Package* : download built library as apt package and install it.

*Built from mod. source* alongside *modified* : source code already downloaded with ORB-SLAM3's github (in its *Thirdparty/* directory). Build and installation made with `build.sh`. This is because librarys' code is slightly modified by ORB-SLAM3 authors.  

@[split](2, end)

@[split](2, begin)

## *As Package* installation pattern
It is possible to install a dependency as a package. This will download binary files and place them in `/usr/lib` or `/usr/lib/bin` directory. Here is the command for Eigen3

![Package installation pattern](https://dvic.devinci.fr/api/v3/img/full/wgbuo0p8hmjrvnyjdo9v3ik3me954x.png)

@[split](2, break)

### *Usual "build from git" pattern*

Most of the dependencies' binary packages can be installed via `apt`-like package managers like shown above. Although this technic is very easy, it may not have all options. In comparaison building from source allows better control over installed version, installation location, present features and hardware compatibility. 

Here is the usual "build from github source" patern used in the [save Github](https://github.com/LMWafer/orb-slam-3-ready) for **Pangolin**. It is  

![Git pattern](https://dvic.devinci.fr/api/v3/img/thumbnail/6k8mzht4yvss0iboak2w792wr5wd1t.png)

`make install` copies the built `.so` files to `/usr/local` or `/usr/local/bin`. These are usual locations where cmake - a build file generator that will be used later - will look for libraries. 

@[split](2, end)

# Level 1 - Create fast and robust application with *C++*

## Step 1.1 Create application code
Once everything is set up an application can be created. Let's enter the details of a real-time vSLAM run written in C++. 

@[split](2, begin)

1.Include needed libraries. OpenCV is used to resize image, the other deps are called internally by ORB-SLAM3. 

![include library](https://dvic.devinci.fr/api/v3/img/thumbnail/o64lmwem45m7cx8r2qnu80kjbwu7jh.png)

@[split](2, break)

2.Select the camera. Realsense SDK handles multiple devices, here only the first available is used. If only one camera is connected, this will also work. 

![Select camera](https://dvic.devinci.fr/api/v3/img/thumbnail/gi9o38gpp46d4tsdalrdwxvddzsqdb.png)

@[split](2, end)

@[split](2, begin)

3.Get infrared images. They are made available by creating a stream-like object that transfers them to a callback function. 

![Get image](https://dvic.devinci.fr/api/v3/img/thumbnail/c5yu0r0e1vqezziya4ba4qpwngr9jg.png)

@[split](2, break)

4.Compute the vSLAM for each frame. `arg[1]` and `arg[2]` come from the executable input argument: DBoW2 vocabulary and vSALM settings.

![Compute SLAM](https://dvic.devinci.fr/api/v3/img/thumbnail/45atkyfuvuj0ger8nnmw68w66sso8f.png)

@[split](2, end)

These are juste file fragment. Find the source code on [Github](https://github.com/UZ-SLAMLab/ORB_SLAM3/blob/master/Examples/Monocular/mono_realsense_D435i.cc)

## Step 1.2 Build application
Building the application would requires a very long command to indicate where each dependency is, which compiler to use etc. In order to speed up the process a CMakeLists gives all the parameters used. 

### Prepare build with a CMakeLists.txt

@[split](2, begin)

1.Check and select compiler version. The cmake file looks for CXX11 or CXX0X version. Here is the 

![Compiler version](https://dvic.devinci.fr/api/v3/img/thumbnail/tv7t73130a9sra89bwnr91yt3v9ava.png)

@[split](2, break)

2.Look for dependencies. This will fill `\<package\>_INCLUDE_DIR` and `\<package\>_LIBRARY` variables. Version and REQUIRED flags can be added to raise errors when mismatches are met. 
![Find package](https://dvic.devinci.fr/api/v3/img/thumbnail/3m7vvclht76sgaqkpqs0m351t44i6h.png)

@[split](2, end)

@[split](2, begin)

3.Create an executable. 

![Create executable](https://dvic.devinci.fr/api/v3/img/thumbnail/6afo1b88k0hg23p2howf6x1s5ejo35.png)

@[split](2, break)

4.Include directories where libraries' `.h` are located. Header files allow future `.cpp` app files to use library's functions' signature while making complied definitions available. 

![Inlude directories](https://dvic.devinci.fr/api/v3/img/thumbnail/neoe44603wn832id2tdpbktz3ou123.png)

@[split](2, end)

5.Link libraries to the exectuable. This is the part that will look for `.so` files. 

![Link libraries](https://dvic.devinci.fr/api/v3/img/thumbnail/chbwh3iobrryt5zl1aewp3br4v60du.png)

### Build the executable
Once the CMakeLists.txt is ready, a build folder can be created at the project's root to run this command inside

![Build executable](https://dvic.devinci.fr/api/v3/img/thumbnail/xeehiciqa0bofbuue1ci9u8yd1pimw.png)

# Level 2 - Add versatility with *Python bindings*

# Level 3 - Share your application to world with *Docker*

@[split](2, begin)

All installation process has already been done in a ready to use Docker image. Run the following command to enter a dev-ready container

![Docker run](https://dvic.devinci.fr/api/v3/img/thumbnail/zxsft1qjwjf8fhhc9ozjoym3ua9s8h.png)

@[split](2, break)

Since ORB-SLAM3 features real-time examples, the monocular one can be run with 

![SLAM run](https://dvic.devinci.fr/api/v3/img/thumbnail/nl20lkzxlju4chu8tqcda7wsbjo9yf.png)

@[split](2, end)

More info on [Dockerhub](https://hub.docker.com/r/lmwafer/orb-slam-3-ready) and [Github](https://github.com/LMWafer/orb-slam-3-ready)

# Images

@[split](2, begin)

![DVIC Cartography](https://dvic.devinci.fr/api/v3/img/thumbnail/917itne3a6zrxusnsf3piyhh0o29c1.png)
Map of the DVIC's made by a drone. Trajectory in green lines. 

@[split](2, break)

![Destroyer](https://dvic.devinci.fr/api/v3/img/thumbnail/dze6kbhyxwvpn7mld3q5zmqavietdp.png)
Point cloud of an object, here a Star Wars toy. 

@[split](2, end)

![Drone vSLAM](https://dvic.devinci.fr/api/v3/img/thumbnail/faghncfr4g6kw331jdg9dzhnxqocqi.png)
Drone POV during mapping. 

# References

[^1]: D. Nister, O. Naroditsky and J. Bergen, "Visual odometry," Proceedings of the 2004 IEEE Computer Society Conference on Computer Vision and Pattern Recognition, 2004. CVPR 2004., 2004, pp. I-I, doi: 10.1109/CVPR.2004.1315094.

[^2]: Davison, "Real-time simultaneous localisation and mapping with a single camera." Proceedings Ninth IEEE International Conference on Computer Vision, 2003, pp. 1403-1410 vol.2, doi: 10.1109/ICCV.2003.1238654.

[^3]: Karlsson, N.; Di Bernardo, E.; Ostrowski, J.; Goncalves, L.; Pirjanian, P.; Munich, M.E. *"The vSLAM algorithm for robust localization and mapping."* In Proceedings of the 2005 IEEE International Conference on Robotics and Automation, Barcelona, Spain,
18–22 April 2005; pp. 24–29.

[^4]: Vidal, A. R., Rebecq, H., Horstschaefer, T., & Scaramuzza, D. (2018). Ultimate SLAM? Combining events, images, and IMU for robust visual SLAM in HDR and high-speed scenarios. IEEE Robotics and Automation Letters, 3(2), 994-1001.

[^5]: A. Rosinol, M. Abate, Y. Chang, and L. Carlone, “Kimera: an open-source library for real-time metric-semantic localization and mapping,” in IEEE International Conference on Robotics and Automation (ICRA),
2020, pp. 1689–1696.

[^6]: V. Usenko, N. Demmel, D. Schubert, J. St ̈uckler, and D. Cremers,
“Visual-inertial mapping with non-linear factor recovery,” IEEE Robotics
and Automation Letters, vol. 5, no. 2, pp. 422–429, April 2020.

[^7]: J. Zubizarreta, I. Aguinaga, and J. M. M. Montiel, “Direct sparse
mapping,” IEEE Transactions on Robotics, vol. 36, no. 4, pp. 1363–
1370, 2020

[^8]: Raúl Mur-Artal, J. M. M. Montiel and Juan D. Tardós. *"ORB-SLAM: A Versatile and Accurate Monocular SLAM System."* IEEE Transactions on Robotics, vol. 31, no. 5, pp. 1147-1163, 2015.

[^9]: Raúl Mur-Artal and Juan D. Tardós. *"ORB-SLAM2: an Open-Source SLAM System for Monocular, Stereo and RGB-D Cameras."* IEEE Transactions on Robotics, vol. 33, no. 5, pp. 1255-1262, 2017

[^10]: Carlos Campos, Richard Elvira, Juan J. Gómez Rodríguez, José M. M. Montiel and Juan D. Tardós, *"ORB-SLAM3: An Accurate Open-Source Library for Visual, Visual-Inertial and Multi-Map SLAM"*, IEEE Transactions on Robotics 37(6):1874-1890, Dec. 2021

[^11]: Ethan Rublee, Vincent Rabaud, Kurt Konolige, Gary R. Bradski: ORB: An efficient alternative to SIFT or SURF. ICCV 2011: 2564-2571

[^12]: Richard Elvira, J. M. M. Montiel and Juan D. Tardós, ORBSLAM-Atlas: a robust and accurate multi-map system, IROS 2019.

[^13]: Bradski, G. *"The OpenCV Library"* Dr. Dobb's Journal of Software Tools, 2008-01-15

[^14]: Rainer Kümmerle, Giorgio Grisetti, Hauke Strasdat, Kurt Konolige, Wolfram Burgard *"G²o: A general framework for graph optimization", 2011 IEEE International Conference on Robotics and Automation, 9-13 May 2011

[^15]: D. G ́alvez-L ́opez and J. D. Tard ́os, *“Bags of binary words for fast place recognition in image sequences.”* IEEE Transactions on Robotics, vol. 28, no. 5, pp. 1188–1197, October 2012.