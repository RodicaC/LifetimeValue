# LifetimeValue
 estimate the expected lifetime of the user

The product that generated this data is a browser.
Each event is a separate line in the file. Each line contains four fields separated by tabs, in order:
    - date
    - event type
    - event data
    - country code

The event type:
    - impbeacon - a visit on a page.
    - dnserror - incorrect url.
    - birthbeacon - initial event from a user.
    - the rest can be ignored

The event data field is a json containing data about the navigation. The following fields are interesting:
    - appInstanceUid - an unique user identifier.
    - location - the visited website
    - vertical - the category of the website
    - features - a list of integer identifiers that represent features active in the browser on that page. The significance of the codes is not available at the moment.
    - os - the operating system and version on which the app runs
