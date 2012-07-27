//
//  Flipper.mm
//  PhysicsBox2d
//
//  Created by Steffen Itterheim on 22.09.10.
//  Copyright 2010 Steffen Itterheim. All rights reserved.
//

#import "Flipper.h"
#import "b2Math.h"
#import "b2RevoluteJoint.h"

@interface Flipper (PrivateMethods)
-(void) attachFlipperAt:(b2Vec2)pos;
@end


@implementation Flipper

-(id) initWithWorld:(b2World*)world flipperType:(EFlipperType)flipperType
{
    NSString* name = (flipperType == kFlipperLeft) ? @"flipper-left" : @"flipper-right";
    
	if ((self = [super initWithShape:name inWord:world]))
	{
		type = flipperType;
		
        // set the position depending on the left or right side
		CGPoint flipperPos = (type == kFlipperRight) ? ccp(210,65) : ccp(90,65)	;

		// attach the flipper to a static body with a revolute joint, so it can move up/down
		[self attachFlipperAt:[Helper toMeters:flipperPos]];

        // listen to touches
		[[CCDirector sharedDirector].touchDispatcher addTargetedDelegate:self priority:0 swallowsTouches:NO];
	}
	return self;
}

+(id) flipperWithWorld:(b2World*)world flipperType:(EFlipperType)flipperType
{
	return [[[self alloc] initWithWorld:world flipperType:flipperType] autorelease];
}

-(void) dealloc
{
    // stop listening to touches
	[[CCDirector sharedDirector].touchDispatcher removeDelegate:self];
    
	[super dealloc];
}

-(void) attachFlipperAt:(b2Vec2)pos
{
    body->SetTransform(pos, 0);
    body->SetType(b2_dynamicBody);

    // the flippers move fast - in some cases
    // if the ball also moves fast it sometimes happens
    // that the flippers skip the ball
    // to avoid this we use continuous collision detection
    body->SetBullet(true);

	// create an invisible static body to attach to‘
	b2BodyDef bodyDef;
	bodyDef.position = pos;
	b2Body* staticBody = body->GetWorld()->CreateBody(&bodyDef);

    // setup joint parameters
	b2RevoluteJointDef jointDef;
	jointDef.Initialize(staticBody, body, staticBody->GetWorldCenter());
	jointDef.lowerAngle = 0.0f;
	jointDef.upperAngle = CC_DEGREES_TO_RADIANS(70);
	jointDef.enableLimit = true;
	jointDef.maxMotorTorque = 100.0f;
	jointDef.motorSpeed = -40.0f;
	jointDef.enableMotor = true;

	if (type == kFlipperRight)
	{
        // mirror speed and angle for the right flipper
		jointDef.motorSpeed *= -1;
		jointDef.lowerAngle = -jointDef.upperAngle;
		jointDef.upperAngle = 0.0f;
	}

    // create the joint
	joint = (b2RevoluteJoint*)body->GetWorld()->CreateJoint(&jointDef);
}

-(void) reverseMotor
{
	joint->SetMotorSpeed(joint->GetMotorSpeed() * -1);
}

-(bool) isTouchForMe:(CGPoint)location
{
	if ((type == kFlipperLeft) && (location.x < [Helper screenCenter].x))
	{
		return YES;
	}
	else if ((type == kFlipperRight) && (location.x > [Helper screenCenter].x))
	{
		return YES;
	}
	
	return NO;
}

-(BOOL) ccTouchBegan:(UITouch*)touch withEvent:(UIEvent*)event
{
	BOOL touchHandled = NO;
	
	CGPoint location = [Helper locationFromTouch:touch];
	if ([self isTouchForMe:location])
	{
		touchHandled = YES;
		[self reverseMotor];
	}
	
	return touchHandled;
}

-(void) ccTouchEnded:(UITouch*)touch withEvent:(UIEvent*)event
{
	CGPoint location = [Helper locationFromTouch:touch];
	if ([self isTouchForMe:location])
	{
		[self reverseMotor];
	}
}

@end
