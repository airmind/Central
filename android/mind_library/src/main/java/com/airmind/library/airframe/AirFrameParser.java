package com.airmind.library.airframe;

import android.content.Context;
import android.util.Xml;
import android.widget.Toast;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by KiBa on 2017/2/11.
 */

public class AirFrameParser {

    public static AirframesMetaData parseAirFrameMetaData(Context context){
        XmlPullParser parser = Xml.newPullParser();
        try {
            InputStream metaDataInputStream = context.getAssets().open("AirframeFactMetaData.xml");
            parser.setInput(metaDataInputStream, "UTF-8");
            int eventType = parser.getEventType();
            // build a new AirframesMetaData Object
            AirframesMetaData airframesMetaData = new AirframesMetaData();
            // airframe-group list
            List<AirframesMetaData.AirframeGroup> airframeGroupList = new ArrayList<>();
            // airframe list
            List<AirframesMetaData.AirFrame> airFrameList = null;
            // output list
            List<AirframesMetaData.Output> outputList = null;
            // AirFrame Object
            AirframesMetaData.AirFrame airFrame = null;
            // AirframeGroup Object
            AirframesMetaData.AirframeGroup airframeGroup = null;

            while (eventType != XmlPullParser.END_DOCUMENT){
                switch (eventType) {

                    case XmlPullParser.START_DOCUMENT:
                        break;

                    case XmlPullParser.START_TAG:

                        /* airframe_group */
                        if(parser.getName() != null && parser.getName().equals("airframe_group")){
                            // build a new airframe list
                            airFrameList = new ArrayList<>();
                            // build a new output list
                            outputList = new ArrayList<>();

                            airframeGroup = new AirframesMetaData.AirframeGroup();
                            // airframe-group properties
                            String image = parser.getAttributeValue(null, "image");
                            String name = parser.getAttributeValue(null, "name");
                            airframeGroup.setImage(image);
                            airframeGroup.setName(name);
                        }

                        /* airframe */
                        if(parser.getName() != null && parser.getName().equals("airframe")){
                            airFrame = new AirframesMetaData.AirFrame();
                            String id = parser.getAttributeValue(null, "id");
                            String maintainer = parser.getAttributeValue(null, "maintainer");
                            String name = parser.getAttributeValue(null, "name");
                            airFrame.setId(id);
                            airFrame.setMaintainer(maintainer);
                            airFrame.setName(name);
                        }

                        /* output */
                        if(parser.getName() != null && parser.getName().equals("output")){
                            AirframesMetaData.Output output = new AirframesMetaData.Output();
                            String angle = parser.getAttributeValue(null, "angle");
                            String direction = parser.getAttributeValue(null, "direction");
                            String name = parser.getAttributeValue(null , "name");
                            String text = parser.nextText();
                            output.setAngle(angle);
                            output.setDirection(direction);
                            output.setName(name);
                            output.setText(text);
                            if(outputList != null){
                                outputList.add(output);
                            }
                        }

                        /* type */
                        if(parser.getName() != null && parser.getName().equals("type")){
                            String type = parser.nextText();
                            if(airFrame != null){
                                airFrame.setType(type);
                            }
                        }

                        /* url */
                        if(parser.getName() != null && parser.getName().equals("url")){
                            String url = parser.nextText();
                            if(airFrame != null){
                                airFrame.setUrl(url);
                            }
                        }

                        break;

                    case XmlPullParser.END_TAG:

                        /* airframe */
                        if(parser.getName() != null && parser.getName().equals("airframe")){
                            if(airFrame != null){
                                airFrame.setOutputList(outputList);
                            }
                            if(airFrameList != null){
                                airFrameList.add(airFrame);
                            }
                        }

                        /* airframe_group */
                        if(parser.getName() != null && parser.getName().equals("airframe_group")){
                            if(airframeGroup != null){
                                airframeGroup.setAirFrameList(airFrameList);
                                airframeGroupList.add(airframeGroup);
                            }
                        }
                        break;
                    default:
                        break;
                }

                eventType = parser.next();
            }

            airframesMetaData.setAirframeGroupList(airframeGroupList);

            return airframesMetaData;
        } catch (IOException e) {
            Toast.makeText(context, "Air frames not found.", Toast.LENGTH_SHORT).show();
        } catch (XmlPullParserException e) {
            Toast.makeText(context, "Parse air frames error.", Toast.LENGTH_SHORT).show();
        }
        return null;
    }

}
