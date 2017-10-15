package org.airmind.view;

import android.app.Activity;
import android.content.Context;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

/**
 * Created by KiBa on 2016/9/22.
 */

public abstract class MindSkinBaseLayout extends FrameLayout {

    protected Context context;
    protected View contentView; // current content view
    protected Activity rootActivity; // parent view
    protected ViewGroup rootViewGroup;

    protected boolean canTouch = true;

    protected abstract View createView();
    protected abstract void onViewCreated(View view, View parent);

    public MindSkinBaseLayout(Activity rootActivity, ViewGroup rootViewGroup) {
        super(rootActivity.getApplicationContext());
        this.context = rootActivity.getApplicationContext();
        this.rootActivity = rootActivity;
        this.rootViewGroup = rootViewGroup;
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        contentView = createView();
        if(contentView != null){
            this.addView(contentView);
            onViewCreated(contentView, this);
        }
    }

    public View getContentView() {
        return contentView;
    }

    public Activity getRootActivity() {
        return rootActivity;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if(canTouch){
            return super.onTouchEvent(event);
        }
        return false;
    }

    public boolean canTouch() {
        return canTouch;
    }

    public void setTouchable(boolean canTouch) {
        this.canTouch = canTouch;
    }
}
