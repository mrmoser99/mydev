public class JSONFinancialProducts {


    public List<Data> data;
    public Pagination pagination;
    

    public class Pagination {
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer itemCount;
        public Links links;
    }
    
    public class Links {
        public String self;
        public String first;
        public String next;
        public String prev;
        public String last;
    }
    
    public class Data {
        public String id;
        public String name;
        public List<String> purchaseOptions;
        public String url;
    }

}