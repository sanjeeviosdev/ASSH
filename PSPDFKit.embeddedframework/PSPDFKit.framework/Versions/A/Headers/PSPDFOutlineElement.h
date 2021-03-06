//
//  PSPDFOutlineElement.h
//  PSPDFKit
//
//  Copyright 2011-2013 Peter Steinberger. All rights reserved.
//

#import "PSPDFBookmark.h"

/// Represents a single outline/table of contents element.
@interface PSPDFOutlineElement : PSPDFBookmark

/// Init with title, page, child elements and indentation level.
- (id)initWithTitle:(NSString *)title action:(PSPDFAction *)action children:(NSArray *)children level:(NSUInteger)level;

/// Returns all elements + flattened subelements if they are expanded
- (NSArray *)flattenedChildren;

/// All elements, ignores expanded state.
- (NSArray *)allFlattenedChildren;

/// Outline title.
@property (nonatomic, copy) NSString *title;

/// Child elements.
@property (nonatomic, copy, readonly) NSArray *children;

/// Current outline level.
@property (nonatomic, assign) NSUInteger level;

/// Expansion state of current outline element (will not be persisted)
@property (nonatomic, assign, getter=isExpanded) BOOL expanded;

@end


@interface PSPDFOutlineElement (Deprecated)

@property (nonatomic, copy, readonly) NSString *destinationName __attribute__ ((deprecated("Use action.destinationName instead")));
@property (nonatomic, copy) NSString *relativePath __attribute__ ((deprecated("Use action.relativePath instead")));

@end
