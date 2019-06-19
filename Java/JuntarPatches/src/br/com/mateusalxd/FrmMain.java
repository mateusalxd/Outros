/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package br.com.mateusalxd;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.ListIterator;
import javax.swing.JOptionPane;

/**
 *
 * @author Mateus
 */
public class FrmMain extends javax.swing.JFrame {

    /**
     * Custom
     */
    private void prepararEstruturaBanco() {
        try (Connection conexao = DriverManager.getConnection("jdbc:sqlite:resumo.db");
                Statement declaracao = conexao.createStatement();) {
            declaracao.executeUpdate("create table if not exists tbl_elemento (id_elemento integer primary key autoincrement, tp_elemento varchar(3) not null, nm_elemento_completo text not null, nm_elemento_pai text not null, nm_elemento text not null, nm_extensao text)");
            declaracao.executeUpdate("delete from tbl_elemento");
            declaracao.executeUpdate("create table if not exists tbl_linha_driver (id_linha_driver integer primary key autoincrement, id_elemento integer not null, nr_linha integer not null, ds_linha text)");
            declaracao.executeUpdate("delete from tbl_linha_driver");
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(null, ex.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
            System.exit(ex.getErrorCode());
        }
    }

    private String recuperarExtensaoArquivo(String nomeCompleto) {
        try {
            return nomeCompleto.substring(nomeCompleto.lastIndexOf("."));
        } catch (Exception e) {
            return "";
        }
    }

    private void listarArquivos(String diretorioOrigem) {
        Connection conexao = null;
        PreparedStatement declaracao = null;
        try {
            conexao = DriverManager.getConnection("jdbc:sqlite:resumo.db");
            declaracao = conexao.prepareStatement("insert into tbl_elemento (tp_elemento, nm_elemento_completo, nm_elemento_pai, nm_elemento, nm_extensao) values (?, ?, ?, ?, ?)");
            conexao.setAutoCommit(false);

            // referência: https://stackoverflow.com/questions/10431981/remove-elements-from-collection-while-iterating
            File diretorio = new File(diretorioOrigem);
            List<String> arquivos = new ArrayList<>();
            for (String d : diretorio.list()) {
                arquivos.add(diretorioOrigem + d);
            }
            ListIterator<String> lista = arquivos.listIterator();

            String extensao;
            do {
                if (lista.hasNext()) {
                    String nomeElemento = lista.next();
                    lista.remove();

                    File elemento = new File(nomeElemento);
                    if (elemento.isDirectory()) {
                        declaracao.setString(1, "d");
                        declaracao.setString(2, nomeElemento);
                        declaracao.setString(3, elemento.getParent() + File.separator);
                        declaracao.setString(4, elemento.getName());
                        extensao = recuperarExtensaoArquivo(elemento.getName());
                        if (!extensao.isEmpty()) {
                            declaracao.setString(5, extensao);
                        } else {
                            declaracao.setNull(5, Types.VARCHAR);
                        }
                        declaracao.executeUpdate();
                        for (String e : elemento.list()) {
                            String nomeElementoInterno = nomeElemento + File.separator + e;
                            File elementoInterno = new File(nomeElementoInterno);
                            if (elementoInterno.isDirectory()) {
                                lista.add(nomeElementoInterno);
                                lista.previous();
                            } else if (elementoInterno.isFile()) {
                                declaracao.setString(1, "a");
                                declaracao.setString(2, nomeElementoInterno);
                                declaracao.setString(3, elementoInterno.getParent() + File.separator);
                                declaracao.setString(4, elementoInterno.getName());
                                extensao = recuperarExtensaoArquivo(elementoInterno.getName());
                                if (!extensao.isEmpty()) {
                                    declaracao.setString(5, extensao);
                                } else {
                                    declaracao.setNull(5, Types.VARCHAR);
                                }
                                declaracao.executeUpdate();
                            } else {
                                declaracao.setString(1, "o");
                                declaracao.setString(2, nomeElementoInterno);
                                declaracao.setString(3, elementoInterno.getParent() + File.separator);
                                declaracao.setString(4, elementoInterno.getName());
                                extensao = recuperarExtensaoArquivo(elementoInterno.getName());
                                if (!extensao.isEmpty()) {
                                    declaracao.setString(5, extensao);
                                } else {
                                    declaracao.setNull(5, Types.VARCHAR);
                                }
                                declaracao.executeUpdate();
                            }
                        }
                    } else if (elemento.isFile()) {
                        declaracao.setString(1, "a");
                        declaracao.setString(2, nomeElemento);
                        declaracao.setString(3, elemento.getParent() + File.separator);
                        declaracao.setString(4, elemento.getName());
                        extensao = recuperarExtensaoArquivo(elemento.getName());
                        if (!extensao.isEmpty()) {
                            declaracao.setString(5, extensao);
                        } else {
                            declaracao.setNull(5, Types.VARCHAR);
                        }
                        declaracao.executeUpdate();
                    } else {
                        declaracao.setString(1, "o");
                        declaracao.setString(2, nomeElemento);
                        declaracao.setString(3, elemento.getParent() + File.separator);
                        declaracao.setString(4, elemento.getName());
                        extensao = recuperarExtensaoArquivo(elemento.getName());
                        if (!extensao.isEmpty()) {
                            declaracao.setString(5, extensao);
                        } else {
                            declaracao.setNull(5, Types.VARCHAR);
                        }
                        declaracao.executeUpdate();
                    }
                }
            } while (lista.hasNext());
            conexao.commit();
        } catch (SQLException ex) {
            try {
                if (conexao != null) {
                    conexao.rollback();
                }
            } catch (SQLException ex2) {
                JOptionPane.showMessageDialog(null, ex2.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
                System.exit(ex.getErrorCode());
            }

            JOptionPane.showMessageDialog(null, ex.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
            System.exit(ex.getErrorCode());
        } finally {
            try {
                if (conexao != null) {
                    conexao.close();
                }

                if (declaracao != null) {
                    declaracao.close();
                }
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(null, ex.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
                System.exit(ex.getErrorCode());
            }
        }
    }

    private void prepararDriver() {
        Connection conexao = null;
        Statement declaracaoConsulta = null;
        ResultSet resultadoConsulta = null;
        PreparedStatement declaracao = null;
        try {
            conexao = DriverManager.getConnection("jdbc:sqlite:resumo.db");
            conexao.setAutoCommit(false);
            declaracaoConsulta = conexao.createStatement();
            resultadoConsulta = declaracaoConsulta.executeQuery("select id_elemento, nm_elemento_completo from tbl_elemento where nm_extensao like '.drv' order by nm_elemento_pai, tp_elemento, nm_elemento");
            declaracao = conexao.prepareStatement("insert into tbl_linha_driver (id_elemento, nr_linha, ds_linha) values (?, ?, ?)");

            int numeroLinha;
            while (resultadoConsulta.next()) {
                numeroLinha = 1;
                try {
                    BufferedReader br = new BufferedReader(
                            new InputStreamReader(
                                    new FileInputStream(resultadoConsulta.getString("nm_elemento_completo")),
                                    "cp1252"));
                    String linha;
                    while ((linha = br.readLine()) != null) {
                        declaracao.setInt(1, resultadoConsulta.getInt("id_elemento"));
                        declaracao.setInt(2, numeroLinha++);
                        declaracao.setString(3, linha);
                        declaracao.executeUpdate();
                    }
                    br.close();
                } catch (FileNotFoundException ex) {
                    jtxtLog.append("Arquivo de drive " + resultadoConsulta.getString("nm_elemento_completo") + " não encontrado (ignorado).");
                } catch (IOException ex) {
                    jtxtLog.append("Erro de leitura no drive " + resultadoConsulta.getString("nm_elemento_completo") + " (ignorado).");
                } catch (SQLException ex) {
                    jtxtLog.append(ex.getMessage() + " (ignorado).");
                }
            }

            conexao.commit();
        } catch (SQLException ex) {
            try {
                if (conexao != null) {
                    conexao.rollback();
                }
            } catch (SQLException ex2) {
                JOptionPane.showMessageDialog(null, ex2.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
                System.exit(ex.getErrorCode());
            }

            JOptionPane.showMessageDialog(null, ex.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
            System.exit(ex.getErrorCode());
        } finally {
            try {
                if (conexao != null) {
                    conexao.close();
                }

                if (declaracaoConsulta != null) {
                    declaracaoConsulta.close();
                }

                if (resultadoConsulta != null) {
                    resultadoConsulta.close();
                }

                if (declaracao != null) {
                    declaracao.close();
                }
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(null, ex.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
                System.exit(ex.getErrorCode());
            }
        }
    }

    /**
     * Creates new form FrmMain
     */
    public FrmMain() {
        initComponents();
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jLabel1 = new javax.swing.JLabel();
        jtxtDiretorioOrigem = new javax.swing.JTextField();
        jLabel2 = new javax.swing.JLabel();
        jtxtNomePatch = new javax.swing.JTextField();
        jLabel3 = new javax.swing.JLabel();
        jtxtDiretorioDestino = new javax.swing.JTextField();
        jLabel4 = new javax.swing.JLabel();
        jScrollPane1 = new javax.swing.JScrollPane();
        jtxtLog = new javax.swing.JTextArea();
        jbtnIniciar = new javax.swing.JButton();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setTitle("Juntar Patches");

        jLabel1.setText("Diretório de origem");

        jtxtDiretorioOrigem.addFocusListener(new java.awt.event.FocusAdapter() {
            public void focusLost(java.awt.event.FocusEvent evt) {
                jtxtDiretorioOrigemFocusLost(evt);
            }
        });

        jLabel2.setText("Nome do novo patch");

        jLabel3.setText("Diretório de destino");

        jtxtDiretorioDestino.addFocusListener(new java.awt.event.FocusAdapter() {
            public void focusLost(java.awt.event.FocusEvent evt) {
                jtxtDiretorioDestinoFocusLost(evt);
            }
        });

        jLabel4.setText("Log");

        jtxtLog.setEditable(false);
        jtxtLog.setColumns(20);
        jtxtLog.setRows(5);
        jScrollPane1.setViewportView(jtxtLog);

        jbtnIniciar.setText("Iniciar");
        jbtnIniciar.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jbtnIniciarActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jtxtDiretorioOrigem)
                    .addComponent(jtxtNomePatch)
                    .addComponent(jtxtDiretorioDestino)
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jLabel1)
                            .addComponent(jLabel2)
                            .addComponent(jLabel3)
                            .addComponent(jLabel4))
                        .addGap(0, 0, Short.MAX_VALUE))
                    .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 380, Short.MAX_VALUE)
                    .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                        .addGap(0, 0, Short.MAX_VALUE)
                        .addComponent(jbtnIniciar)))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jLabel1)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jtxtDiretorioOrigem, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jLabel2)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jtxtNomePatch, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jLabel3)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jtxtDiretorioDestino, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jLabel4)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 260, Short.MAX_VALUE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jbtnIniciar)
                .addContainerGap())
        );

        pack();
        setLocationRelativeTo(null);
    }// </editor-fold>//GEN-END:initComponents

    private void jbtnIniciarActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jbtnIniciarActionPerformed
        jtxtLog.append("Montando estrutura do banco de dados...");
        prepararEstruturaBanco();
        jtxtLog.append("\nListando arquivos e diretórios...");
        listarArquivos(jtxtDiretorioOrigem.getText());
        jtxtLog.append("\nValidando drivers...");
        prepararDriver();
    }//GEN-LAST:event_jbtnIniciarActionPerformed

    private void jtxtDiretorioOrigemFocusLost(java.awt.event.FocusEvent evt) {//GEN-FIRST:event_jtxtDiretorioOrigemFocusLost
        if (!jtxtDiretorioOrigem.getText().isEmpty()) {
            if (!jtxtDiretorioOrigem.getText().endsWith(File.separator)) {
                jtxtDiretorioOrigem.setText(jtxtDiretorioOrigem.getText() + File.separator);
            }

            if (!new File(jtxtDiretorioOrigem.getText()).exists()) {
                JOptionPane.showMessageDialog(null, "Diretório de origem não existe.", "Erro", JOptionPane.ERROR_MESSAGE);
                jtxtDiretorioOrigem.requestFocus();
            }
        }
    }//GEN-LAST:event_jtxtDiretorioOrigemFocusLost

    private void jtxtDiretorioDestinoFocusLost(java.awt.event.FocusEvent evt) {//GEN-FIRST:event_jtxtDiretorioDestinoFocusLost
        if (!jtxtDiretorioDestino.getText().isEmpty()) {
            if (!jtxtDiretorioDestino.getText().endsWith(File.separator)) {
                jtxtDiretorioDestino.setText(jtxtDiretorioDestino.getText() + File.separator);
            }

            if (!new File(jtxtDiretorioDestino.getText()).exists()) {
                JOptionPane.showMessageDialog(null, "Diretório de destino não existe.", "Erro", JOptionPane.ERROR_MESSAGE);
                jtxtDiretorioDestino.requestFocus();
            }
        }
    }//GEN-LAST:event_jtxtDiretorioDestinoFocusLost

    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /* Set the Nimbus look and feel */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html 
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(FrmMain.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(FrmMain.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(FrmMain.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(FrmMain.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new FrmMain().setVisible(true);
            }
        });
    }

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel4;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JButton jbtnIniciar;
    private javax.swing.JTextField jtxtDiretorioDestino;
    private javax.swing.JTextField jtxtDiretorioOrigem;
    private javax.swing.JTextArea jtxtLog;
    private javax.swing.JTextField jtxtNomePatch;
    // End of variables declaration//GEN-END:variables
}
