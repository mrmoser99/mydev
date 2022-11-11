/**
 * Created by samuelmeyers on 12/27/18.
 */

public class VendorProgramTriggerHelper {

    public static void helpBeforeInsert(List<Vendor_Program__c> newVPs){
        setInitialValues(newVPs);
        setBusinessUnit(newVPs);
    }
 
    public static void setInitialValues(List<Vendor_Program__c> vps){
        for(Vendor_Program__c vp : vps){
            if(String.isBlank(vp.Source_System__c)){
                vp.Source_System__c = 'GDW_Wayne';
                vp.Location__c = 'United States';
                vp.Name = vp.UNQ_Vendor_Program__c;
            }
        }
    }

    public static void setBusinessUnit(List<Vendor_Program__c> vps){
        Map<String, String> businessUnits = new Map<String, String>{
                'Digital Imaging' => 'Digital Imaging',
                'Construction, Transportation, and Industrial' => 'Construction, Transportation, and Industrial',
                'Technology' => 'Technology',
                'CleanTech' => 'CleanTech',
                'Healthcare' => 'Healthcare',
                'Office Equipment' => 'Digital Imaging',
                'Financial Institutions' => 'Digital Imaging',
                'Materials Handling and Construction' => 'Construction, Transportation, and Industrial',
                'Materials Handling' => 'Construction, Transportation, and Industrial',
                'Technology Finance' => 'Technology',
                'Clean Technology Group' => 'CleanTech'
        };
        for(Vendor_Program__c vp : vps){
            if(vp.Source_System__c == 'GDW_Wayne') {
                String bu = businessUnits.get(vp.Business_Unit_New__c);
                if (bu != null) {
                    vp.Business_Unit_New__c = bu;
                } else {
                    vp.Business_Unit_New__c = 'Other';
                }
            }
        }
    } 
}