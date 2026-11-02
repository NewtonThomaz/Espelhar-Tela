package com.newton.espelhartela;

import android.app.Activity;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.text.InputType;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends Activity {

    private static final String PREFS_NAME = "espelhar_prefs";
    private static final String KEY_CUSTOM_IP = "custom_ip";
    private static final String KEY_LAST_PC_IP = "last_pc_ip";
    private static final int DEFAULT_PORT = 8888;

    private TextView statusText;
    private EditText ipInput;
    private Button toggleBtn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        final SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setBackgroundColor(Color.parseColor("#0F172A"));
        int pad = dp(28);
        root.setPadding(pad, pad, pad, pad);

        TextView title = new TextView(this);
        title.setText("Espelhar Tela no PC");
        title.setTextColor(Color.WHITE);
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 24);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setGravity(Gravity.CENTER);
        root.addView(title);

        TextView subtitle = new TextView(this);
        subtitle.setText("Descoberta automática via Wi-Fi (Broadcast UDP)");
        subtitle.setTextColor(Color.parseColor("#94A3B8"));
        subtitle.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        subtitle.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams subLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        subLp.topMargin = dp(8);
        subLp.bottomMargin = dp(36);
        root.addView(subtitle, subLp);

        // Big Circular/Rounded Toggle Button
        toggleBtn = new Button(this);
        toggleBtn.setText("ESPELHAR AGORA");
        toggleBtn.setTextColor(Color.WHITE);
        toggleBtn.setTextSize(TypedValue.COMPLEX_UNIT_SP, 18);
        toggleBtn.setTypeface(Typeface.DEFAULT_BOLD);
        toggleBtn.setAllCaps(false);

        GradientDrawable btnBg = new GradientDrawable();
        btnBg.setColor(Color.parseColor("#10B981"));
        btnBg.setCornerRadius(dp(90));
        toggleBtn.setBackground(btnBg);

        LinearLayout.LayoutParams btnLp = new LinearLayout.LayoutParams(dp(220), dp(220));
        btnLp.bottomMargin = dp(28);
        root.addView(toggleBtn, btnLp);

        statusText = new TextView(this);
        String lastPc = prefs.getString(KEY_LAST_PC_IP, "");
        if (!lastPc.isEmpty()) {
            statusText.setText("Último PC detectado: " + lastPc);
        } else {
            statusText.setText("Toque no botão para iniciar ou encerrar o espelhamento");
        }
        statusText.setTextColor(Color.parseColor("#38BDF8"));
        statusText.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        statusText.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams statusLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        statusLp.bottomMargin = dp(32);
        root.addView(statusText, statusLp);

        // Optional Manual IP Field (collapsed/subtle for edge cases)
        TextView ipLabel = new TextView(this);
        ipLabel.setText("IP do PC (opcional — deixe em branco para automático):");
        ipLabel.setTextColor(Color.parseColor("#64748B"));
        ipLabel.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        ipLabel.setGravity(Gravity.CENTER);
        root.addView(ipLabel);

        ipInput = new EditText(this);
        ipInput.setHint("Automático (255.255.255.255)");
        ipInput.setHintTextColor(Color.parseColor("#475569"));
        ipInput.setTextColor(Color.WHITE);
        ipInput.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        ipInput.setGravity(Gravity.CENTER);
        ipInput.setInputType(InputType.TYPE_CLASS_TEXT);
        ipInput.setText(prefs.getString(KEY_CUSTOM_IP, ""));

        GradientDrawable inputBg = new GradientDrawable();
        inputBg.setColor(Color.parseColor("#1E293B"));
        inputBg.setCornerRadius(dp(12));
        inputBg.setStroke(dp(1), Color.parseColor("#334155"));
        ipInput.setBackground(inputBg);
        ipInput.setPadding(dp(16), dp(10), dp(16), dp(10));

        LinearLayout.LayoutParams ipLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        ipLp.topMargin = dp(8);
        root.addView(ipInput, ipLp);

        setContentView(root);

        toggleBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                triggerMirror(prefs);
            }
        });
    }

    private void triggerMirror(final SharedPreferences prefs) {
        final String customIp = ipInput.getText().toString().trim();
        prefs.edit().putString(KEY_CUSTOM_IP, customIp).apply();

        statusText.setText("Enviando comando via Broadcast UDP...");
        toggleBtn.setEnabled(false);

        UdpToggleSender.sendToggle(customIp, DEFAULT_PORT, new UdpToggleSender.Callback() {
            @Override
            public void onResult(final boolean ackReceived, final String pcIp, final String error) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        toggleBtn.setEnabled(true);
                        if (error != null) {
                            statusText.setText("Erro: " + error);
                            Toast.makeText(MainActivity.this, "Erro ao enviar: " + error, Toast.LENGTH_SHORT).show();
                        } else if (ackReceived && pcIp != null) {
                            prefs.edit().putString(KEY_LAST_PC_IP, pcIp).apply();
                            statusText.setText("Conectado! PC respondeu em " + pcIp);
                            Toast.makeText(MainActivity.this, "Espelhamento alternado (" + pcIp + ")", Toast.LENGTH_SHORT).show();
                        } else {
                            statusText.setText("Sinal enviado na rede Wi-Fi (porta 8888)!");
                            Toast.makeText(MainActivity.this, "Comando enviado para o PC!", Toast.LENGTH_SHORT).show();
                        }
                    }
                });
            }
        });
    }

    private int dp(int value) {
        return (int) TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP,
                value,
                getResources().getDisplayMetrics()
        );
    }
}

