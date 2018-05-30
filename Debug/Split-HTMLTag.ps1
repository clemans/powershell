<# 
.SYNOPSIS
  Receives string input and attempts to parse HTML header information accordingly.

.DESCRIPTION
  This cmdlet takes string input and attempts to separate the beginning header (e.g. <head>) from the 
  ending header (e.g. </head>) and creates and object which can be used to pipe to other cmdlets for
  advanced webrequests.

.PARAMETER 
 -HTML <String>
        A string line of HTML code. Example: $HTML="<head>This is the title of the webpage.</head>"

.NOTES
  Version:        1.0   
  Author:         clemans
  Creation Date:  02/22/2018

.EXAMPLES
    $HTML="<head>This is the title of the webpage.</head>"; Parse-HTMLTags -HTML $url | FL
#>

    
Param(
       [Parameter(mandatory=$true,ValueFromPipeline=$true)]$HTML
     )
    
#Declare array variables
    if  ($HTML.GetType().BaseType.Name.Equals('Array'))
    {
        $HTMLHeaders = $HTML.Values;
    }
                 
#Declare object variable
    if  ($HTML.GetType().BaseType.Name.Equals('Object'))
    {
        $HTMLHeaders = $HTML;
    }

#Parsing logic
    Foreach ($HTML in $HTMLHeaders)
    {
	
  	    if ($HTML -notlike '*.+*')
	    {
		    if ($HTML -like '*></*')
		    {
                $HTML = [System.Array]($HTML -replace "\\","").Replace("></","> </").Split(" ")
                $head    = ($HTML -join " ").Replace($HTML[-1],'')
                $end     = (($HTML -replace "\\","").Replace("></","> </").Split(" "))[-1]
		    }
	    }
    
        if ($HTML -like '*.+*')
	    {
	        $HTML=[System.Array]($HTML -replace "\\","").Replace(".+"," ").Split(" ")
            $head  = ($HTML -join " ").Replace($HTML[-1],'')
            $end   = (($HTML -replace "\\","").Replace(".+"," ").Split(" "))[-1]
    	}

#Create parsed object(s)
    $psobj  = New-Object psobject 
    $psobj  | Add-Member NoteProperty Head $head
    $psobj  | Add-Member NoteProperty End $end
    $psobj  | Select-Object Head,End
    }