/* Written by Mathias Wagner www.linkedin.com/in/mathias-wagner */
/* Tweeked by by Pravhat Pandey */


// Global debug setting
// true: print info for every event
// false: print info for only newly colorized event
const DEBUG = false


/* Entry for the whole colorizing magic.
   Select this function when deploying it and assigning a trigger function
*/
function colorizeCalendar() {
 
  const pastDays = 1 // looking 1 day back to catch last minute changes
  const futureDays = 7 * 4 // looking 4 weeks into the future
 
  const now       = new Date()
  const startDate = new Date(now.setDate(now.getDate() - pastDays))
  const endDate   = new Date(now.setDate(now.getDate() + futureDays))
  // Extracting the domain of your email, e.g. company.com
  const myOrg     = CalendarApp.getDefaultCalendar().getName().split("@")[1];
 
  // Get all calender events within the defined range
  // For now only from the default calendar
  var calendarEvents = CalendarApp.getDefaultCalendar().getEvents(startDate, endDate)


  if (DEBUG) {
   console.log("Calendar default org: " + myOrg)
  }

  // Walk through all events, check and colorize
  for (var i=0; i<calendarEvents.length; i++) {


    // Skip for better performance, else go to colorizing below
    if (skipCheck(calendarEvents[i])) {
      continue
    }
    colorizeByRegex(calendarEvents[i], myOrg)
  }
}


/* Performance tweak: skip all events, that do no longer have the DEFAULT color,
   or have been declined already.
   This avoids overriding user settings and doesn't burn regex / string ops
   for allready adjusted event colors.


   @param CalendarEvent
*/
function skipCheck(event) {


 if(event.getColor() != "" || event.getMyStatus() == CalendarApp.GuestStatus.NO) {
      if(DEBUG) {
        console.log("Skipping already colored / declined event:" + event.getTitle())
      }
      return true
    }
 return false
}


/**
 * Maps a hex color to the closest Google Calendar color using EventColor enum
 * @param {string} hexColor - Hex color code (e.g., "#8CAAEEFF")
 * @return {string} The closest Calendar EventColor enum value
 */
function mapHexToCalendarColor(hexColor) {
  // Define calendar colors with their respective enum values
  const calendarColors = {
    "1": { name: CalendarApp.EventColor.PALE_BLUE, displayName: "Peacock", background: "#A4BDFC" },
    "2": { name: CalendarApp.EventColor.PALE_GREEN, displayName: "Sage", background: "#7AE7BF" },
    "3": { name: CalendarApp.EventColor.MAUVE, displayName: "Grape", background: "#DBADFF" },
    "4": { name: CalendarApp.EventColor.PALE_RED, displayName: "Flamingo", background: "#FF887C" },
    "5": { name: CalendarApp.EventColor.YELLOW, displayName: "Banana", background: "#FBD75B" },
    "6": { name: CalendarApp.EventColor.ORANGE, displayName: "Tangerine", background: "#FFB878" },
    "7": { name: CalendarApp.EventColor.CYAN, displayName: "Lavender", background: "#46D6DB" },
    "8": { name: CalendarApp.EventColor.GRAY, displayName: "Graphite", background: "#E1E1E1" },
    "9": { name: CalendarApp.EventColor.BLUE, displayName: "Blueberry", background: "#5484ED" },
    "10": { name: CalendarApp.EventColor.GREEN, displayName: "Basil", background: "#51B749" },
    "11": { name: CalendarApp.EventColor.RED, displayName: "Tomato", background: "#DC2127" }
  };
  
  // Convert hex to RGB (handling 8-character hex with alpha if provided)
  const hexToRgb = (hex) => {
    // Remove # if present
    hex = hex.replace(/^#/, '');
    
    // Handle both 6-character and 8-character hex (with alpha)
    const hexColor = hex.length === 8 ? hex.substring(0, 6) : hex;
    
    // Parse RGB values
    const r = parseInt(hexColor.substring(0, 2), 16);
    const g = parseInt(hexColor.substring(2, 4), 16);
    const b = parseInt(hexColor.substring(4, 6), 16);
    
    return { r, g, b };
  };
  
  // Calculate color distance (simple Euclidean distance)
  const colorDistance = (color1, color2) => {
    const rgb1 = hexToRgb(color1);
    const rgb2 = hexToRgb(color2);
    return Math.sqrt(
      Math.pow(rgb1.r - rgb2.r, 2) +
      Math.pow(rgb1.g - rgb2.g, 2) +
      Math.pow(rgb1.b - rgb2.b, 2)
    );
  };
  
  // Find closest color
  let closestId = "1";
  let minDistance = Number.MAX_VALUE;
  let closestColor = CalendarApp.EventColor.PALE_BLUE;
  
  for (const [id, colorObj] of Object.entries(calendarColors)) {
    const distance = colorDistance(hexColor, colorObj.background);
    if (distance < minDistance) {
      minDistance = distance;
      closestId = id;
      closestColor = colorObj.name;
    }
  }
  
  return closestColor;
}

/**
 * Gets the actual color palette from the Calendar API
 * @return {Object} Object with colorIds as keys and color information as values
 */
function getCalendarColorPalette() {
  try {
    // Get the color definitions from the Calendar API
    const colors = CalendarApp.getDefaultCalendar().getColor();
    console.log("colors: ", colors);
    console.log("hex: sss", CalendarApp.EventColor.PALE_BLUE)
    return colors;
  } catch (e) {
    Logger.log('Error getting calendar colors: ' + e.toString());
    throw new Error('Failed to get calendar colors. Make sure the Calendar API is enabled in Advanced Google Services.');
  }
}

/**
 * Extracts the HEX color value from a string containing "Tag Color: #XXXXXXXX" pattern
 * @param {string} text - The input text containing the tag color information
 * @return {string} The extracted HEX color value or an empty string if not found
 */
function extractTagColor(text) {
  // Check if text is provided
  if (!text) return "";
  
  // Define the regex pattern to match "Tag Color: #" followed by hex characters
  const colorPattern = /Tag Color: (#[0-9A-Fa-f]+)/;
  
  // Execute the regex pattern on the input text
  const match = text.match(colorPattern);
  
  // Return the matched hex color or empty string if not found
  return match ? match[1] : "";
}


/* Actual colorizing of events based on Regex matching.
   Makes only sense for frequent stuff you want to auto colorize.
   Order matters for performance! Function exits after first matching color set.
   
   https://developers.google.com/apps-script/reference/calendar/event-color
   Mapping of Google Calendar color names to API color names (Kudos to Jason!):
   https://lukeboyle.com/blog/posts/google-calendar-api-color-id
   @param CalendarEvent
   @param String
*/
function colorizeByRegex(event, myOrg) {


  // Converting to lower case for easier matching.
  // Keep lower case in mind when defining your regex(s) below!
    const noteText = event.getDescription()
    const hexColor = extractTagColor(noteText);
    const colorId = mapHexToCalendarColor(hexColor);


    // Check for travel related entries
    if(hexColor) {
      console.log("Colorizing: " + event.getTitle())
      console.log("hex value: " + hexColor)
      console.log("closest color index: " + colorId)
      event.setColor(colorId)
      return
    }

    // No match found, therefore no colorizing
    else {
      console.log("No matching rule for: " + noteText)
    }
}