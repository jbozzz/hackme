This is a repository for the deployment of Hack this Server. It is an implementation of a basic Linux based Apache/Tomcat JSP server. Hack this Server has two purposes:
1. Providing (wannabe) hackers and security professionals with a real environment they are allowed to hack
2. Providing a reference implementation of a web server with security controls based on actual hacks

The idea is that the basic installation is a standard out-of-the-box implementation without any hardening controls. This allow for hackers to hack the system and gain access. Hackers who succeed in doing this are required to fix the installation by closing the security hole they just used to compromise the system. The documentation of the fix should include a description of the way the security vulnerability was used to gain access and how to prevent this from happening again. This way, each hacker makes the system a bit more secure. It should also give you a sense how secure a standard Tomcat/Linux implementation is. Of course the security of a web server is very much dependent on the security of the web application itself. At this stage however the focus is on the infrastructure running the application.

The system consists of the following parts:

- a basic Linux/Apache2/Tomcat/MySQL installation with a basic web application
- a host based and Network IDS to allow for monitoring attacks in real-time and doing a post-mortem analysis. The IDS is configured to report only and is not meant to actively prevent attacks. On the other hand, the IDS itself should not be used as an attack vector as it is not considered part of the regular web server
- a series of security enhancements for each successful hack

The installation is based on an Ubuntu desktop installation. The desktop was chosen because it has many services running that allow for exploitation. Ans also because the desktop version may be the version of choice for people starting with Ubuntu as a web hosting platform that do not have mach experience with the command line interface of Linux.
Installation on a blank Ubuntu desktop is done with the command 

wget https://github.com/jbozzz/hackme/raw/master/server/basicinstall.sh; sudo chmod +x basicinstall.sh; sudo ./basicinstall.sh
