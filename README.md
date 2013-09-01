# Intruduction

An open source Twitter client using [Shadowsocks](http://www.shadowsocks.com) proxy for chinese citizen.

# Screenshots

<img src="https://github.com/tuoxie007/Tweet4China2/raw/master/Screenshots/1.PNG" style="max-width: 320px;"/>
<img src="https://github.com/tuoxie007/Tweet4China2/raw/master/Screenshots/2.PNG" style="max-width: 320px;"/>
<img src="https://github.com/tuoxie007/Tweet4China2/raw/master/Screenshots/3.PNG" style="max-width: 320px;"/>
<img src="https://github.com/tuoxie007/Tweet4China2/raw/master/Screenshots/4.PNG" style="max-width: 320px;"/>
<img src="https://github.com/tuoxie007/Tweet4China2/raw/master/Screenshots/5.PNG" style="max-width: 320px;"/>
<img src="https://github.com/tuoxie007/Tweet4China2/raw/master/Screenshots/6.PNG" style="max-width: 320px;"/>
<img src="https://github.com/tuoxie007/Tweet4China2/raw/master/Screenshots/7.PNG" style="max-width: 320px;"/>
<img src="https://github.com/tuoxie007/Tweet4China2/raw/master/Screenshots/8.PNG" style="max-width: 320px;"/>

# Usage

## Require:
* An iOS Device, version >= 7.0, may be some problems on simulator
* A Shadowsocks server, see [Shadowsocks project](http://www.shadowsocks.com)
* Build on Xcode 5

## Clone submodule recursively

	git submodule update --recursive --init
	open iOS/Tweet4China/Tweet4China.xcodeproj

## Apply your twitter application

* Find your twitter Consumer key & Consumer secrect in [dev.twitter.com/apps](https://dev.twitter.com/apps).
* Define kTwitterAppKey & kTwitterAppSecrect in HSUDefinitions.h file.

## Still need help?

Ask me on twitter, [@tuoxie007](https://twitter.com/tuoxie007)