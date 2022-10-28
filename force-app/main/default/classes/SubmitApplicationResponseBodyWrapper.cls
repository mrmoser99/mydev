/**
 * This class is used in RESTCallout service class to handle callout response. 
 * It provides request body wrapper for Submit Application callout
 * 
 * @author Elena Sokolova @date 2021-01-15
 */
public with sharing class SubmitApplicationResponseBodyWrapper extends BaseResponseBodyWrapper {

    public String contractNumber;

    /**
     * Method sets class variables by response body deserialization.
     * Override the parent class method with this signature.
     */
    public override BaseResponseBodyWrapper deserialize(String className, String responseString) {

        SubmitApplicationResponseBodyWrapper wrapper = new SubmitApplicationResponseBodyWrapper();

        // deserialize response body when response is successful
        if (this.statusCode == 200) {
            wrapper = (SubmitApplicationResponseBodyWrapper) JSON.deserialize(responseString, Type.forName(className));
        } 

        // set statuc code (parent class variable)
        wrapper.statusCode = this.statusCode;
        
        return wrapper; 
    }
}