/**
* Name: SmartCommRequestBodyWrapper 
* Purpose: This class is used as forming the JSON structure for the SmartComm API request.
* It provides request body wrapper for SmartComm callout
* 
* Version 1.0 @author Neha Bansal @date 2021-07-21
* */
public class SmartCommRequestBodyWrapper extends BaseRequestBodyWrapper {
    
    public Integer projectId;
    public Integer batchConfigResId;
    public String transactionData;
    public String transactionRange;
    public String transactionDataType;
    public List<Properties> properties;
   
  
    public class Properties {
        public String name;
        public String value;
        
        public Properties(String name , String value ){
            this.name=name;
            this.value=value;
        }
        
    }
    
    /**
     * Method sets class variables.
     * Override the parent class method with this signature.
     */
    public override void init(Map<String, object> params) {  
        this.projectId = Integer.valueOf(params.get('projectId'));
        this.batchConfigResId= Integer.valueOf(params.get('batchConfigData'));
        this.transactionData= (String)params.get('transData');
        this.transactionRange= (String)params.get('transRange');
        this.transactionDataType= (String)params.get('transDataType');
       
            
        List<Properties> propList = new List<Properties>();
        propList.add(new Properties('merge.pdf','true'));
        this.properties=propList;
    }
    
}