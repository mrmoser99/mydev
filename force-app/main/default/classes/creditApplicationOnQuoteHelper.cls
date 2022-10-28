/**
 * Author: Kritika Sharma & Surbhi Goyal: Traction on Demand
 * Date : 24/02/2022.
 */

public class creditApplicationOnQuoteHelper {
    
    // This method performs the primary quote conversion to the credit application.
    public static void updateOpportunityByQuote(List<Quote> quoteList) {
        Set<Id> opportunityIds = new Set<Id>();

        // Get is primary Quote List that's have opportunity
        List<Quote> isPrimaryQuoteList = [
            SELECT Id,
                Advance_Payments__c,
                Amount__c,
                End_User__c,
                Finance_Term_Month__c,
                Interest__c,
                Is_Primary__c,
                Lease_Type__c,
                Opportunity.Advance_Payments__c,
                Opportunity.Amount,
                Opportunity.End_User__c,
                Opportunity.End_User__r.Phone,
                Opportunity.Frequency__c,
                Opportunity.Interest_Rate__c,
                Opportunity.Lease_Type__c,
                Opportunity.Owner.Phone,
                Opportunity.Partner_Sales_Rep__c,
                Opportunity.Payment_Amount__c,
                Opportunity.Rate_Type__c,
                Opportunity.Residual_Amount__c,
                Opportunity.Term__c,
                OpportunityId,
                Partner_Sales_Rep__c,
                Payment_Frequency__c,
                Rate_Type__c,
                Residual__c,
                Term__c,
                Total_Payment__c
            FROM Quote
            WHERE Id In :quoteList
            AND Is_Primary__c = true
            AND OpportunityId != null
            AND Opportunity.Sub_Stage__c = 'Quoting & Proposal'
        ];
        for(Quote quote:isPrimaryQuoteList) {
            opportunityIds.add(quote.OpportunityId);
        }

        // Ensure there are opportunities in this stage before attempting the conversion.
        if(opportunityIds.size() > 0){
            List<Opportunity> opportunityList = [
                    SELECT Id,
                            Advance_Payments__c,
                            End_User__c,
                            Frequency__c,
                            Lease_Type__c,
                            Partner_Sales_Rep__c,
                            Rate_Type__c,
                            Term__c
                    FROM Opportunity
                    WHERE Id In :opportunityIds
            ];

            // Query the assets related to the primary quote (not bulkified, assumes a single quote conversion at a time).
            Map<Id, Decimal> numberOfAssets = new Map<Id, Decimal>();
            List<Quote_Line__c> quoteLines = [
                    SELECT Id,
                            Base_Unit_Sales_Price__c,
                            Equipment_Type__c,
                            Name,
                            Number_of_Units__c
                    FROM Quote_Line__c
                    WHERE Quote__c = :isPrimaryQuoteList[0].Id
            ];

            // Create the list of opportunity lines (again, not bulkified assuming one).
            List<Opportunity_Line_Item__c> oppLines = new List<Opportunity_Line_Item__c>();
            Opportunity_Line_Item__c oppLine = new Opportunity_Line_Item__c();
            Decimal distinctAssets = 0;
            for(Quote_Line__c quoteLine:quoteLines){

                // Tally up the total number of assets considering unit counts.
                if(quoteLine.Equipment_Type__c == 'Asset'){
                    distinctAssets = distinctAssets + quoteLine.Number_of_Units__c;
                }

                // Blow out the number of quote line units into individualized records.
                for(Integer i = 0; i < quoteLine.Number_of_Units__c; i++){
                    oppLine = new Opportunity_Line_Item__c();
                    oppLine.Amount__c = quoteLine.Base_Unit_Sales_Price__c;
                    oppLine.Name = quoteLine.Name;
                    oppLine.Line_Item_Type__c = quoteLine.Equipment_Type__c;
                    oppLine.Opportunity__c = isPrimaryQuoteList[0].OpportunityId;
                    oppLine.Related_Quote_Line__c = quoteLine.Id;
                    oppLines.add(oppLine);
                }
            }
            insert oppLines;
            numberOfAssets.put(isPrimaryQuoteList[0].OpportunityId, distinctAssets);

            // Stamp the values from quote to opportunity
            for(Opportunity opp:opportunityList){
                for(Quote quote : isPrimaryQuoteList) {
                    if(opp.Id == quote.OpportunityId) {
                        if(quote.Advance_Payments__c != null){
                            opp.Advance_Payments__c = decimal.valueof(quote.Advance_Payments__c);
                        }
                        opp.Amount = quote.Amount__c;

                        opp.Frequency__c = quote.Payment_Frequency__c;

                        // Populate a phone number
                        if(quote.Opportunity.End_User__r.Phone != null && quote.Opportunity.End_User__r.Phone != ''){
                            opp.End_User_Phone__c = quote.Opportunity.End_User__r.Phone;
                        } else {
                            opp.End_User_Phone__c = quote.Opportunity.Owner.Phone;
                        }

                        if(quote.Interest__c != null) {
                            opp.Interest_Rate__c = decimal.valueof(quote.Interest__c);
                        }

                        // Transform the lease type label
                        if(quote.Lease_Type__c == 'BO'){
                            opp.Lease_Type__c = label.CREDITAPP_LEASETYPE;
                        } else {
                            opp.Lease_Type__c = quote.Lease_Type__c;
                        }

                        // Stamp the number of assets if it exists.
                        if(numberOfAssets.containsKey(quote.OpportunityId)){
                            opp.Number_of_Assets__c = numberOfAssets.get(quote.OpportunityId);
                        }

                        opp.Partner_Sales_Rep__c = quote.Partner_Sales_Rep__c;
                        opp.Payment_Amount__c = quote.Total_Payment__c;
                        opp.Rate_Type__c = quote.Rate_Type__c;
                        opp.Residual_Amount__c = quote.Residual__c;
                        opp.Sub_Stage__c = 'Application Draft';
                        if(quote.Term__c != null) {
                            opp.Term__c = decimal.valueof(quote.Term__c);
                        }
                    }
                }
            }
            Database.update(opportunityList);
        }
    }
}