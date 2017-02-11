package org.airmind.view;

import android.app.Dialog;
import android.content.DialogInterface;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.support.v4.view.ViewPager;
import android.support.v7.widget.AppCompatSpinner;
import android.util.Log;
import android.util.Xml;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import com.airmind.library.airframe.AirFrameParser;
import com.airmind.library.airframe.AirframesMetaData;

import org.airmind.ble.VehicleManager;
import org.airmind.view.adapter.AirFrameSpinnerAdapter;
import org.airmind.view.adapter.FrameTypePagerAdapter;
import org.mavlink.qgroundcontrol.R;
import org.qgroundcontrol.qgchelper.MindSkinActivity;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by KiBa on 2017/1/4.
 */

public class MainActivity extends MindSkinActivity {

    private TextView flightTextView;
    private AirframesMetaData airframesMetaData;
    private String airFrameId = null;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if(getActionBar() != null){
            getActionBar().hide();
        }

        setContentView(R.layout.activity_qt);

        flightTextView = (TextView) findViewById(R.id.activity_qt_flight);

        init();
    }

    private void init(){

        flightTextView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showFrameTypeWarningDialog();
            }
        });
    }

    private void showFrameTypeWarningDialog(){
        CommonAlertDialog dialog = new CommonAlertDialog(this, "Air frame not found, please set the frame type.");
        dialog.setPositiveListener(new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                showFrameSelectDialog();
            }
        });
        dialog.show();
    }

    private void showFrameSelectDialog(){
        // parse airframe meta data and convert to an object
        if(airframesMetaData == null){
            airframesMetaData = AirFrameParser.parseAirFrameMetaData(getApplicationContext());
        }

        if(airframesMetaData != null){
            Dialog dialog = new Dialog(this, R.style.MindSkinDialog);
            View view = LayoutInflater.from(getApplicationContext()).inflate(R.layout.dialog_select_frame_type, null);
            ImageView leftArrow = (ImageView) view.findViewById(R.id.dialog_select_frame_type_left_imageView);
            ImageView rightArrow = (ImageView) view.findViewById(R.id.dialog_select_frame_type_right_imageView);
            final ViewPager viewPager = (ViewPager) view.findViewById(R.id.dialog_select_frame_type_viewPager);

            List<View> views = new ArrayList<>();
            for (int i = 0; i < airframesMetaData.getAirframesCount(); i++) {
                // air frame group list
                AirframesMetaData.AirframeGroup airframeGroup = airframesMetaData.getAirframeGroupList().get(i);
                // air frame list
                List<AirframesMetaData.AirFrame> airFrames = airframeGroup.getAirFrameList();

                View viewToAdd = View.inflate(getApplicationContext(), R.layout.child_select_frame_type, null);
                TextView nameTextView = (TextView) viewToAdd.findViewById(R.id.child_select_frame_name_textView);
                AppCompatSpinner spinner = (AppCompatSpinner) viewToAdd.findViewById(R.id.child_select_frame_spinner);
                final Button btnSelect = (Button) viewToAdd.findViewById(R.id.child_select_frame_btn);
                // name text
                nameTextView.setText(airframeGroup.getName());
                // select btn
                btnSelect.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        if(airFrameId == null){
                            Toast.makeText(MainActivity.this, "Please select a frame type.", Toast.LENGTH_SHORT).show();
                            return;
                        }
                        Toast.makeText(MainActivity.this, airFrameId + "", Toast.LENGTH_SHORT).show();
                    }
                });
                // set spinner
//                final AirFrameSpinnerAdapter adapter = new AirFrameSpinnerAdapter(getApplicationContext(), airFrames);
                List<String> airframeDataList = new ArrayList<>();
                final List<String> airframeIdList = new ArrayList<>();
                for (AirframesMetaData.AirFrame airFrame : airFrames) {
                    airframeDataList.add(airFrame.getName());
                    airframeIdList.add(airFrame.getId());
                }
                final ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, airframeDataList);
                adapter.setDropDownViewResource(R.layout.child_spinner_dropdown_item);
                spinner.setAdapter(adapter);
                spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                    @Override
                    public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                        airFrameId = airframeIdList.get(position);
                        if(airFrameId != null){
                            VehicleManager.setAirFrameType(Integer.valueOf(airFrameId));
                            // TODO: 2017/2/18
                        }else{
                            Toast.makeText(getApplicationContext(), "No frame id detected.", Toast.LENGTH_SHORT).show();
                        }
                    }

                    @Override
                    public void onNothingSelected(AdapterView<?> parent) {
                        airFrameId = null;
                    }
                });
                spinner.setSelection(0);
                views.add(viewToAdd);
            }

            final FrameTypePagerAdapter adapter = new FrameTypePagerAdapter(views);
            viewPager.setAdapter(adapter);

            leftArrow.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    int currentPosition = viewPager.getCurrentItem();
                    if(currentPosition != 0){
                        viewPager.setCurrentItem(currentPosition - 1);
                    }
                }
            });

            rightArrow.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    int currentPosition = viewPager.getCurrentItem();
                    if(currentPosition != (adapter.getCount() - 1)){
                        viewPager.setCurrentItem(currentPosition + 1);
                    }
                }
            });

            dialog.setContentView(view);
            dialog.setCancelable(false);
            dialog.setTitle("Select AirFrames");
            dialog.show();
        }else{
            Toast.makeText(this, "Data parsing error.", Toast.LENGTH_SHORT).show();
        }

    }

}
