package org.airmind.view;

import android.app.Activity;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import org.mavlink.qgroundcontrol.R;

/**
 * Created by KiBa on 2016/9/22.<br/>
 *
 * ViewGroup view = (ViewGroup) this.findViewById(android.R.id.content);
 * if (view != null) {
        MindSkinContainer mindSkinContainer = new MindSkinContainer(this, view);
        view.addView(mindSkinContainer);
    }
 */

public class MindSkinContainer extends MindSkinBaseLayout {

    private TextView flightTextView;

    private RelativeLayout mainMenuLayout;

    private FragmentManager fragmentManager;
    private FragmentTransaction fragmentTransaction;

    public MindSkinContainer(Activity rootActivity, ViewGroup rootParentView) {
        super(rootActivity, rootParentView);
    }

    @Override
    protected View createView() {
        return LayoutInflater.from(context).inflate(R.layout.activity_qt, rootViewGroup, false);
    }

    @Override
    protected void onViewCreated(View view, View parent) {
        flightTextView = (TextView) view.findViewById(R.id.activity_qt_flight);
        mainMenuLayout = (RelativeLayout) view.findViewById(R.id.activity_qt_main_menu_rl);

        fragmentManager = rootActivity.getFragmentManager();

        setViewClickListener();
    }

    private void setViewClickListener() {
        flightTextView.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                Toast.makeText(rootActivity, "click", Toast.LENGTH_SHORT).show();
                FlightFragment fragment = new FlightFragment();
                fragmentTransaction = fragmentManager.beginTransaction();
                if(fragmentTransaction == null){
                    Toast.makeText(context, "fragmentTransaction == null", Toast.LENGTH_SHORT).show();
                }else {
                    fragmentTransaction.add(rootViewGroup.getId(), fragment, "flight");
                    int id = fragmentTransaction.commit();
                    Log.d("kiba", "id == " + id);
                }
            }
        });
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        // TODO: 2016/10/6 返回按钮逻辑
        return super.onKeyDown(keyCode, event);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        super.onLayout(changed, l, t, r, b);
    }

}
