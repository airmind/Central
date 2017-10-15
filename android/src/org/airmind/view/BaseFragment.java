package org.airmind.view;

import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;

/**
 * Created by KiBa on 2016/9/23.
 */

public abstract class BaseFragment extends Fragment {

    protected boolean isVisible = false;

    protected int layoutId = -1;
    protected View layout;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        if(layoutId != -1){
            layout = inflater.inflate(layoutId, container, false);
        }else if(layout != null){
            return layout;
        }else{
            try {
                throw new Exception("layoutId or layout view not set, please setLayout() or setLayoutId() in onCreate().");
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        // touch event can't dispatch to other views
        layout.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                return true;
            }
        });
        return layout;
    }

    @Override
    public void setUserVisibleHint(boolean isVisibleToUser) {
        super.setUserVisibleHint(isVisibleToUser);
        if(getUserVisibleHint()){
            isVisible = true;
            onVisibleToUser();
        }else{
            isVisible = false;
            onInvisibleToUser();
        }
    }
    protected abstract void onInvisibleToUser();
    protected abstract void onVisibleToUser();

    public void setLayout(View layout) {
        this.layout = layout;
    }

    public void setLayoutId(int layoutId) {
        this.layoutId = layoutId;
    }

    public int getLayoutId() {
        return layoutId;
    }

    public View getLayout() {
        return layout;
    }
}
