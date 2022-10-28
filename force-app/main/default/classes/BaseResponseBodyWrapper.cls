/**
 * This class is used in RESTCallout service class to handle callout response. 
 * It is extended to provide request body wrapper for each callout
 * 
 * @author Elena Sokolova @date 2021-01-15
 */
public abstract class BaseResponseBodyWrapper {

    // error id (in case of an error)
    public String id;
    // error message (in case of an error)
    public String message;
    public Integer statusCode;

    /**
     * Method deserializes response of callout and set Status Code.
     * Because it is declared virtual it can be overridden by a subclass.
     * 
     * @return request instance of the class
     */
    public virtual BaseResponseBodyWrapper deserialize(String className, String responseString) {

        BaseResponseBodyWrapper wrapper =  (BaseResponseBodyWrapper) JSON.deserialize(responseString, Type.forName(className));

        wrapper.statusCode = this.statusCode;
        
        return wrapper;
    }
}