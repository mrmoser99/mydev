public class JSONSubmitCreditAppBadRequest {

    public Error error;
    
    public class Error {
        public Integer status;
        public String title;
        public String type;
        public List<Detail> details;    
    }
    
    public class Detail {
        public String detail;
        public String type;
    }

}