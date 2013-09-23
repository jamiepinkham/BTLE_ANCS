BTLE_ANCS
=========

A WIP for connecting to ANCS.

[ANCS](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/AppleNotificationCenterServiceSpecification/Introduction/Introduction.html#//apple_ref/doc/uid/TP40013460-CH2-SW1) is a way for BTLE devices to connect to and read your Notification Center in iOS7. (Think Pebble).

I wanted to see what it was all about, so I wrote a Mac client for ANCS.

A few caveats:
* I wrote this late and quick, it's not the best design. I've spent maybe 5 hours on it total.
* Getting an app's display name [just doesn't work](https://devforums.apple.com/message/876984#876984). In the code's current state, kicking off that transaction will deadlock the transaction queue.
* You have to run the iOS app and tap start broadcasting in order for the Mac client to see the ANCS service. (No clue on that)
* There's no UI. Just watch the log messages.
* Best way to see it in action is get yourself all connected up and then send yourself an iMessage.

```
2013-09-23 00:37:43.662 ANCS[28739:303] notification source characteristic is notifying = YES
2013-09-23 00:37:43.856 ANCS[28739:303] data source characteristic is notifying = YES
2013-09-23 00:37:57.307 ANCS[28739:303] added notification = {
	 eventId : 43
	 categoryCount : 6
	 notificationType : 0
	 eventFlags : 1
	 category : 4
}
2013-09-23 00:37:57.405 ANCS[28739:303] removed notification = {
	 eventId : 40
	 categoryCount : 5
	 notificationType : 2
	 eventFlags : 1
	 category : 4
}
2013-09-23 00:37:57.603 ANCS[28739:303] updated details = {
	 appIdentifier : com.apple.MobileSMS
	 notificationId : 43
	 title : Jamie Pinkham
	 subtitle : 
	 message : i am in your notification center, reading your notifications
	 messageSize : 60
	 date : 2013-09-23 04:37:00 +0000
}
```
![Screenshot here](http://d.pr/i/oYUD+ "Screenshot")
