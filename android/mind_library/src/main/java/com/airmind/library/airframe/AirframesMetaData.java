package com.airmind.library.airframe;

import java.util.List;

/**
 * Created by KiBa on 2017/1/12.
 */

public class AirframesMetaData {

    private int airframesCount;

    private List<AirframeGroup> airframeGroupList;

    public int getAirframesCount() {
        if(airframeGroupList == null){
            return 0;
        }
        return airframeGroupList.size();
    }

    public void setAirframesCount(int airframesCount) {
        this.airframesCount = airframesCount;
    }

    public List<AirframeGroup> getAirframeGroupList() {
        return airframeGroupList;
    }

    public void setAirframeGroupList(List<AirframeGroup> airframeGroupList) {
        this.airframeGroupList = airframeGroupList;
    }

    public static class AirframeGroup{

        private String image;

        private String name;

        private List<AirFrame> airFrameList;

        public String getImage() {
            return image;
        }

        public void setImage(String image) {
            this.image = image;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public List<AirFrame> getAirFrameList() {
            return airFrameList;
        }

        public void setAirFrameList(List<AirFrame> airFrameList) {
            this.airFrameList = airFrameList;
        }
    }

    public static class AirFrame{

        private String id;

        private String maintainer;

        private String name;

        private String type;

        private String url;

        private List<Output> outputList;

        public String getId() {
            return id;
        }

        public void setId(String id) {
            this.id = id;
        }

        public String getMaintainer() {
            return maintainer;
        }

        public void setMaintainer(String maintainer) {
            this.maintainer = maintainer;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getType() {
            return type;
        }

        public void setType(String type) {
            this.type = type;
        }

        public String getUrl() {
            return url;
        }

        public void setUrl(String url) {
            this.url = url;
        }

        public List<Output> getOutputList() {
            return outputList;
        }

        public void setOutputList(List<Output> outputList) {
            this.outputList = outputList;
        }
    }

    public static class Output{

        private String angle;

        private String direction;

        private String name;

        private String text;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getText() {
            return text;
        }

        public String getAngle() {
            return angle;
        }

        public void setAngle(String angle) {
            this.angle = angle;
        }

        public String getDirection() {
            return direction;
        }

        public void setDirection(String direction) {
            this.direction = direction;
        }

        public void setText(String text) {

            this.text = text;
        }
    }

}
