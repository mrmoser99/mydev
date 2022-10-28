trigger calcBusinessHours on Case (before insert, before update) {

// Assumes the DLL work hours are the default for the Org
BusinessHours stdBusinessHours = [select id from businesshours where isDefault = true];

    for (Case c : Trigger.new) {
        if (c.CreatedDate != NULL && stdBusinessHours != NULL) {
        // DLL works 11 hours / day (8:00 AM - 7:00 PM, M-F). SLA is 1-day for Medium priority cases (24 business hours), 2-days for Low and 4 hours for High
            if (c.Priority == 'Medium'){
                c.SLA_Due_Date_Time__c = BusinessHours.add (stdBusinessHours.id, c.CreatedDate,  39600000 );
            }else if (c.Priority == 'High') {
                c.SLA_Due_Date_Time__c = BusinessHours.add (stdBusinessHours.id, c.CreatedDate, 14400000);
            }else {
                c.Priority = 'Low'; 
                c.SLA_Due_Date_Time__c = BusinessHours.add (stdBusinessHours.id, c.CreatedDate, 79200000 );  
            }
        }
    }
}