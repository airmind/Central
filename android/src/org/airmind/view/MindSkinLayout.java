package org.airmind.view;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.RelativeLayout;

import org.mavlink.qgroundcontrol.R;

/**
 * Created by KiBa on 2016/9/22.
 */

public abstract class MindSkinLayout extends RelativeLayout {

    protected Context context;

    protected abstract void onBindView(View view);

    public MindSkinLayout(Context context) {
        super(context);
        this.context = context;
    }

    private void init(){
        View child = LayoutInflater.from(this.context).inflate(R.layout.activity_qt, this, false);
        this.addView(child);
        onBindView(child);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        init();
    }
}
