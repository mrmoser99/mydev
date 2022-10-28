/**
 * This class is used in RESTCallout service class to handle callout response. 
 * It provides request body wrapper for Search Party callout
 * 
 * @author Elena Sokolova @date 2021-01-15
 */
public with sharing class SearchPartyResponseBodyWrapper extends BaseResponseBodyWrapper {

    public List<Data> data;
    public Links links;
    public String id;
    public String message;

    public SearchPartyResponseBodyWrapper() {}

    /**
     * Method sets class variables by response body deserialization.
     * Override the parent class method with this signature.
     */
    public override BaseResponseBodyWrapper deserialize(String className, String responseString) {

        // call parent method to set parent class variables and try to deserialize response body
        SearchPartyResponseBodyWrapper wrapper = (SearchPartyResponseBodyWrapper) super.deserialize(className, responseString);

        /**
         * there is reserved 'number' key in the response body 
         * it has to be replaced by ureserved 'phoneNumbers' word
         */
        Map<String, Object> response =  (Map<String, Object>) JSON.deserializeUntyped(responseString);
        List<Object> dataList = (List<Object>) response.get('data');
        if (dataList != null) {
            for (Object dataItemObject : dataList) {
                Map<String, Object> dataItem = (Map<String, Object>) dataItemObject;
                Integer dataIndex = dataList.indexOf(dataItemObject);
                SearchPartyResponseBodyWrapper.Data dataItemFromWrapper = wrapper.data[dataIndex];
                List<Object> phList = (List<Object>) dataItem.get('phoneNumbers');
                if (phList != null) {
                    for (Object numberItemObject : phList) {
                        Map<String, Object> numberItem = (Map<String, Object>) numberItemObject;
                        Integer phIndex = phList.indexOf(numberItemObject);
                        String phoneNumber = (String) numberItem.get('number');
                        dataItemFromWrapper.phoneNumbers[phIndex].phoneNumber = phoneNumber;
                    }
                }
            }
        }
        return wrapper; 
    }

    public class Data {
        public String name;
        public Address address;
        public LegalEntity legalEntity;
        public List<PhoneNumber> phoneNumbers;
    }

    public class Address {
        public String street;
        public String city;
        public String postalCode;
    }

    public class LegalEntity {
        public String id;
        public String name;
        public String url;
    }

    public class PhoneNumber {
        public String type;
        public String phoneNumber;
        public String areaCode;
    }

    public class Links {
        public String self;
    }
}