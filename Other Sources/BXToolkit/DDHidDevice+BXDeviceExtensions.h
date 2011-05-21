/* 
 Boxer is copyright 2011 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


//BXDeviceExtensions adds some helper methods for creating DDHidDevices from HIDDeviceRefs,
//and extends DDHidDevice subclasses to provide a richer introspection API for finding out
//device capabilities.

#import <DDHidLib/DDHidLib.h>
#import <IOKit/hid/IOHIDLib.h>

io_service_t createServiceFromHIDDevice(IOHIDDeviceRef deviceRef);

@interface DDHidUsage (BXUsageEquality)
- (BOOL) isEqualToUsage: (DDHidUsage *)usage;
@end

@interface DDHidDevice (BXDeviceExtensions)

+ (Class) classForHIDDeviceRef: (IOHIDDeviceRef)deviceRef;

+ (id) deviceWithHIDDeviceRef: (IOHIDDeviceRef)deviceRef
						error: (NSError **)outError;

- (id) initWithHIDDeviceRef: (IOHIDDeviceRef)deviceRef error: (NSError **)error;

- (BOOL) isEqualToDevice: (DDHidDevice *)device;

//Returns an array of all elements matching the specified usage.
//Will be empty if no such elements are present on the device.
- (NSArray *) elementsWithUsage: (DDHidUsage *)usage;
@end


@interface DDHidJoystick (BXJoystickExtensions)

//Arrays of all axis/POV elements/sticks present on this device.
@property (readonly, nonatomic) NSArray *axisElements;
@property (readonly, nonatomic) NSArray *povElements;
@property (readonly, nonatomic) NSArray *sticks;

//Returns all axis elements conforming to the specified usage ID.
//Will be empty if no such axis is present on this device.
- (NSArray *) axisElementsWithUsageID: (unsigned)usageID;

//Returns the first element corresponding to the specified button usage,
//or nil if no such button is present on this device.
- (NSArray *) buttonElementsWithUsageID: (unsigned)usageID;
@end


@interface DDHidJoystickStick (BXJoystickStickExtensions)

//Arrays of all axis/POV elements on this stick.
@property (readonly, nonatomic) NSArray *axisElements;
@property (readonly, nonatomic) NSArray *povElements;

//Returns all axis elements conforming to the specified usage ID.
//Will be empty if no such axis is present on this stick.
- (NSArray *) axisElementsWithUsageID: (unsigned)usageID;

@end