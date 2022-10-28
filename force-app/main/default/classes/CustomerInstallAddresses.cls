/*
* CustomerInstallAddresses: Enables a user to query install addresses related to an end user customer.
* 2022-07-17: Created
*/
public without sharing class CustomerInstallAddresses {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAddresses(Id oppId) {

        // Get the end user from the opportunity.
        Opportunity opp = [
            SELECT End_User__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        // Then get the contracts related to that end user.
        List<Contract__c> contractList = [
            SELECT Id
            FROM Contract__c
            WHERE End_User__c = :opp.End_User__c
            LIMIT 1000
        ];

        // Then get the asset install addresses related to those contracts.
        List<Asset__c> assets = [
            SELECT Asset_City_Install_Address__c,
                Asset_Install_Address_Line_1__c,
                Asset_Install_Address_Line_2__c,
                Asset_Postal_Code_Install_Address__c,
                Asset_State_Install_Address__c
            FROM Asset__c
            WHERE Contract__c IN :contractList
            // ORDER BY Asset_State_Install_Address__c, Asset_City_Install_Address__c // The list gets sorted by street address below.
            LIMIT 1000
        ];

        // Loop through the assets and create a unique list of install addresses.
        List<String> setOfValues = new List<string>();
        for(Asset__c obj :assets) {
            string fullAddress = '';
            fullAddress = string.valueof(obj.Asset_Install_Address_Line_1__c) !=null ? fullAddress + string.valueof(obj.Asset_Install_Address_Line_1__c) : fullAddress;
            fullAddress = string.valueof(obj.Asset_Install_Address_Line_2__c) !=null ? fullAddress + ', ' + fullAddress+string.valueof(obj.Asset_Install_Address_Line_2__c) : fullAddress;
            fullAddress = string.valueof(obj.Asset_City_Install_Address__c) !=null ? fullAddress + ', ' + string.valueof(obj.Asset_City_Install_Address__c) : fullAddress;
            fullAddress = string.valueof(obj.Asset_State_Install_Address__c) !=null ? fullAddress + ', ' + string.valueof(obj.Asset_State_Install_Address__c) : fullAddress;
            fullAddress = string.valueof(obj.Asset_Postal_Code_Install_Address__c) != null ? fullAddress + ', ' + string.valueof(obj.Asset_Postal_Code_Install_Address__c) : fullAddress;
            if(fullAddress != ''){
                setOfValues.add(fullAddress);
            }
        }

        // Then merge in existing opportunity line addresses.
        List<Opportunity_Line_Item__c> oppLineItemList = [
            SELECT Planned_Install_City__c,
                Planned_Install_Date__c,
                Planned_Install_State__c,
                Planned_Install_Street__c,
                Planned_ZIP_Code__c
            FROM Opportunity_Line_Item__c
            WHERE Line_Item_Type__c = 'Asset'
            AND Opportunity__c = :oppId
            // ORDER BY Planned_Install_State__c, Planned_Install_City__c // The list gets sorted by street address below.
        ];

        // Loop through the assets and add to the list.
        for(Opportunity_Line_Item__c obj :oppLineItemList) {
            string fullAddress = '';

            // Break up the street address into two parts.
            if (obj.Planned_Install_Street__c != null) {

                fullAddress = obj.Planned_Install_Street__c;
                /*
                List<String> addressParts = obj.Planned_Install_Street__c.split(',');
                if (addressParts.size() == 1) {
                    fullAddress = addressParts[0];
                }else if (addressParts.size() == 2) {
                    fullAddress = addressParts[0] + ' ' + addressParts[1];
                }
                */
            }

            fullAddress = string.valueof(obj.Planned_Install_City__c) !=null ? fullAddress + ', ' + string.valueof(obj.Planned_Install_City__c) : fullAddress;
            fullAddress = string.valueof(obj.Planned_Install_State__c) !=null ? fullAddress + ', ' + string.valueof(obj.Planned_Install_State__c) : fullAddress;
            fullAddress = string.valueof(obj.Planned_ZIP_Code__c) != null ? fullAddress + ', ' + string.valueof(obj.Planned_ZIP_Code__c) : fullAddress;
            if(fullAddress != ''){
                setOfValues.add(fullAddress);
            }
        }

        // Turn the set into a map.
        Map<String, String> values = new Map<String, String>{};
        setOfValues.sort();
        for(string val :setOfValues) {
            values.put(val, val);
        }

        // Return the map of install values.
        return values;
    }
}