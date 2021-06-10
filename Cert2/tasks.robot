# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library     RPA.Browser.Selenium
Library     RPA.Dialogs

Library     RPA.HTTP
Library     RPA.Excel.Files
Library     RPA.Tables 
Library     RPA.PDF
Library     RPA.Archive
Library     RPA.Robocloud.Secrets

Variables         variables.py


# -


*** Variables ***
${GLOBAL_RETRY_AMOUNT}    100x
${GLOBAL_RETRY_INTERVAL}    2s

*** Keywords *** 
Open Site

   # Using the secret open the browser and navigate to the url 
   ${secret}=    Get Secret    urlSecret
   #Open Available Browser   ${secret}[url]
   
   # Get user input to open browser and navigate to the url
   ${url}=  Collect URL From User
   Open Available Browser   ${url}
   
   
   Maximize Browser Window
   Click Button    CSS:button.btn-dark  


*** Keywords ***
Collect URL From User
    Add text input      url     label=URL query
    ${response}=    Run dialog
    [Return]    ${response.url}

*** Keywords ***
Download CSV and fill in form
    Download   https://robotsparebinindustries.com/orders.csv  overwrite=True
    
    ${robots}=    Read Table From Csv    orders.csv
    
    FOR    ${robots}    IN    @{robots}
        Fill in form for one robot  ${robots}
    END
    
    Log    Done adding robots


*** Keywords ***
Fill in form for one robot
    [Arguments]     ${robots}
    
    Select From List By Value   head    ${robots}[Head]
    Click Element    id-body-2
    Input Text    xpath://html[1]/body[1]/div[1]/div[1]/div[1]/div[1]/div[1]/form[1]/div[3]/input[1]    ${robots}[Legs]
    Input Text    address    ${robots}[Address]
    
    Click Button    id:preview

    Wait Until Keyword Succeeds   ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click Button    order
    Wait Until Keyword Succeeds   ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click Element If Visible    order
    Click Element If Visible    order
    Click Element If Visible    order

    ${order_no}=   Collect the results 
    Send to PDF     ${order_no}
    Click Element If Visible    order-another
    
    Click Element If Visible    CSS:button.btn-dark  
    Wait Until Page Contains Element    head


*** Keywords ***
Collect the results 
    ${order_no}=    Get Text    xpath://p[@class="badge badge-success"]
    [Return]    ${order_no}



# +
*** Keywords ***
Send to PDF
     [Arguments]     ${order_no}
     ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
     
     #${robot_img}=  Get Element Attribute   id:robot-preview-image  outerHTML
     #Html To Pdf    ${robot_img}    ${CURDIR}${/}output${/}${order_no}.pdf
     
          
     
     Html To Pdf    ${sales_results_html}    ${CURDIR}${/}output${/}${order_no}.pdf  # Writes metadata to PDF
     Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${order_no}.png
     
    ${files}=    Create List
    ...    ${CURDIR}${/}output${/}${order_no}.pdf
    ...    ${CURDIR}${/}output${/}${order_no}.png
    Add Files To PDF    ${files}    ${CURDIR}${/}output${/}${order_no}.pdf
     
     
# -


*** Keywords ***
Archive Folder
    Archive Folder With Zip  ${CURDIR}${/}output  Output.zip

*** Tasks ***
 Order a robot from the site and print a reciept
    Open Site
    Download CSV and fill in form
    Archive Folder
